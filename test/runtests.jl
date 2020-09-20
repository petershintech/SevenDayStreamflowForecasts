using SevenDaysStreamflowForecasts

using Test

@testset "SevenDaysStreamflowForecasts" begin
    sdf = SDF()
    @testset "SDF()" begin
        nrows, ncols = size(sdf.sites)
        @test nrows > 0 # At least one site.
        @test ncols > 0 # At least one column.
    end

    @testset "get_forecasts()" begin
        site_ids = ["410730"]
        for awrc_id in site_ids
            data, header = get_forecasts(sdf, awrc_id)

            local nrows, ncols = size(data)
            @test nrows > 0 # At least one data point.
            @test ncols > 0 # At least one column.

            @test length(header) > 0 # At least one header line
        end
        data, header = get_forecasts(sdf, "invalid ID", fc_date)
        @test isempty(data)
        @test isempty(header)
    end
    @testset "show()" begin
        show_str = repr(sdf)
        @test occursin("awrc_id", show_str)
        @test occursin("station_name", show_str)
    end
    @testset "close()" begin
        close!(sdf)
        @test isempty(sdf.sites)
    end
end