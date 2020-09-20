# SevenDayStreamflowForecasts

| **Build Status**                                                                                |
|:----------------------------------------------------------------------------------------------- |
 [![][travis-img]][travis-url] [![][codecov-img]][codecov-url]

A web client for the 7-Day Streamflow Forecasting Service  the Australian Bureau of Meteorology in the Julia programming language. The website at <http://www.bom.gov.au/water/7daystreamflow> provides 3-day ahead streamflow forecasts for catchments across Australia.

## Installation

The package can be installed with the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

````julia
pkg> add SevenDayStreamflowForecasts
````

If you want to install the package directly from its github development site,

````julia
pkg> add http://github.com/petershintech/SevenDayStreamflowForecasts.jl
````

And load the package using the command:

````julia
using SevenDayStreamflowForecasts
````

## Site Information

When you create an instance of the `SDF` structure, it downloads
site information.

````julia
julia> sdf = SDF();
````

Once it is instantiated, the fields of `sdf` should be considered as read-only so don't try to change any values of the fields.

### Site Information

`sdf.sites` has site information including ID, AWRC ID and description.

````julia
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
`````

## Forecasts

`get_forecasts()` returns the most recent forecast data as `DataFrames.DataFrame`. The method needs a site ID.
The returned data have precentiles of ensemble forecasts and historical reference (streamflow climatology) along with the recent observation data.
The site ID of a station can be found in `awrc_id` columne of `sdf.sites`.

````julia
julia> using Dates
julia> site_id = "410730";
julia> data, header = get_forecasts(sdf, site_id);
julia> data
264×13 DataFrame. Omitted printing of 11 columns
│ Row │ Time                  │ Observed Rainfall (mm/hour) │
│     │ String                │ Union{Missing, Float64}     │
├─────┼───────────────────────┼─────────────────────────────┤
│ 1   │ 2020-09-15 10:00 AEST │ 0.0                         │
│ 2   │ 2020-09-15 11:00 AEST │ 0.0                         │
│ 3   │ 2020-09-15 12:00 AEST │ 0.0                         │
│ 4   │ 2020-09-15 13:00 AEST │ 0.0                         │
...
````

## Disclaimer

This project is not related to or endorsed by the Australian Bureau of Meteorology.

The materials downloaded from the 7-Day Streamflow Forecast website are licensed under the [Creative Commons Attribution Australia Licence](https://creativecommons.org/licenses/by/3.0/au/).

[travis-img]: https://travis-ci.org/petershintech/SevenDayStreamflowForecasts.jl.svg?branch=master
[travis-url]: https://travis-ci.org/petershintech/SevenDayStreamflowForecasts.jl

[codecov-img]: https://codecov.io/gh/petershintech/SevenDayStreamflowForecasts.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/petershintech/SevenDayStreamflowForecasts.jl
