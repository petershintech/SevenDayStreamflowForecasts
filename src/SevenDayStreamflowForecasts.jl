module SevenDayStreamflowForecasts

import Base.show
import HTTP
using CSV: File
import JSON
using DataFrames: DataFrame, select!

const SDF_URL = "http://www.bom.gov.au/water/7daystreamflow/"
const SITES_URL = SDF_URL * "content/config/site_config.json"

const SITE_PROPERTIES = ["station_name", "bom_id", "awrc_id",
                         "product_status", "product_id_public",
                         "area", "lat", "lon"]

const HEADER_DELIM = "#"

export SDF, get_forecasts, close!

"""
    sdf = SDF()

Open the connection and download the information of SDF service sites e.g. name, ID, AWRC ID and description.

# Fields
* `sites`: Site information table

# Examples
```julia
julia> sdf = SDF();
julia> sdf.sites
208×8 DataFrame. Omitted printing of 5 columns
│ Row │ station_name                                 │ bom_id │ awrc_id  │
│     │ String                                       │ String │ String   │
├─────┼──────────────────────────────────────────────┼────────┼──────────┤
│ 1   │ Timbarra River D/S Wilkinson Creek           │ 584008 │ 223212   │
│ 2   │ St. Pauls River above Avoca                  │ 592003 │ 18311    │
│ 3   │ Macquarie River D/S Elizabeth River Junction │ 093026 │ 18312    │
│ 4   │ Macquarie River at Fosterville               │ 093059 │ 18313    │
...
```
"""
struct SDF
	sites::DataFrame

	function SDF()
		sites = get_sites()
		new(sites)
	end
end

"""
    sites = get_sites()

Download site information e.g. AWRC ID and names.
"""
function get_sites()::DataFrame
	r = HTTP.get(SITES_URL)

	features = JSON.parse(String(r.body))["stations"]["features"]

	sites = DataFrame()
	for key in SITE_PROPERTIES
		sites[!, key] = [x["properties"][key] for x in features]
	end

    return sites
end

"""
    data, header = get_forecasts(sdf::SDF, site_id::AbstractString)

Return seasonal forecasts of a site.

# Arguments
* `sdf` : SDF object
* `site_id`: AWRC ID of the site. The ID can found in the table from `get_sites()`

# Examples
```julia
julia> using Dates
julia> data, header = get_forecasts(sdf,"410730");
julia> data
264×13 DataFrame. Omitted printing of 10 columns
│ Row │ Time                  │ Observed Rainfall (mm/hour) │ Forecast Rainfall Median (mm/hour) │
│     │ String                │ Union{Missing, Float64}     │ Union{Missing, Float64}            │
├─────┼───────────────────────┼─────────────────────────────┼────────────────────────────────────┤
│ 1   │ 2020-09-15 10:00 AEST │ 0.0                         │ missing                            │
│ 2   │ 2020-09-15 11:00 AEST │ 0.0                         │ missing                            │
│ 3   │ 2020-09-15 12:00 AEST │ 0.0                         │ missing                            │
...
julia> println(header)
Australian Bureau of Meteorology
Short term streamflow forecasts
hourly_barplot_ens
Cotter River at Gingera (410730)
Catchment area:", 130.0,"km^2
...
```
"""
function get_forecasts(sdf::SDF,
                       site_id::AbstractString)::Tuple{DataFrame,String}
    row = sdf.sites[sdf.sites.awrc_id .== site_id, :]
    isempty(row) && return (DataFrame(), "")

    data_url = get_url(site_id, row.product_id_public[1])

	r = HTTP.get(data_url)

	body_buf = IOBuffer(String(r.body))

	header = extract_header!(body_buf, HEADER_DELIM)
	new_header = prune_header(header, HEADER_DELIM)

	body_buf = seek(body_buf, 0)
	data = DataFrame(File(body_buf, comment=HEADER_DELIM, missingstring="-"))

	return data, new_header
end

function show(io::IO, sdf::SDF)
    isempty(sdf.sites) && return
    println("The SDF Sites:")
    show(io, first(sdf.sites, 6))
    println(io)
    println(io, "...")
    return
end

"""
    close!(sdf::SDF)

Close the connection and reset the SDF object.
"""
function close!(sdf::SDF)
    select!(sdf.sites, Int[])
    return
end


"""
    url = get_url(site_id::AbstractString, fc_date::Date,
                  drainage::AbstractString, basin::AbstractString)

Return the URL to download data of a site.
"""
function get_url(site_id::AbstractString, product_id::AbstractString)::AbstractString
    url = "http://www.bom.gov.au/fwo/$(product_id)/data/$(site_id)/$(site_id)_hourly_barplot_ens.csv"
    return url
end

"""
    header = extract_header!(body_buf::Base.GenericIOBuffer{Array{UInt8,1}}, delim::AbstractString)

Extract the header document of the data file. Note that it moves the position of body_buf.
"""
function extract_header!(body_buf::Base.GenericIOBuffer{Array{UInt8,1}},
                         delim::AbstractString)::Array{String,1}
    header = String[]
    for line in eachline(body_buf)
        startswith(line, delim) ? push!(header, line) : break
    end
    return header
end

"""
    new_header = prune_header(header::AbstractString, delim::AbstractString)

Prune the extracted header document. It drops blank lines and double quotations from the raw document.
"""
function prune_header(header::Array{String,1}, delim::AbstractString)::String
    new_header = String[]
    for line in header
        #TODO: Give more information about the format error.
        startswith(line, delim) || throw(IOError("A header line does not start with $(delim)."))

        the_line = rstrip(line[3:end])
        isempty(the_line) && continue
        istart = 1
        i = findfirst('\"', the_line)
        (i != nothing) && (istart = i+1)
        iend = length(the_line)
        (the_line[end] == '\"') && (iend -= 1)

        push!(new_header, the_line[istart:iend])
    end
    return join(new_header, "\n")
end

end # module
