using SASLib, Missings
using Base.Test

@testset "SASLib" begin

    @testset "open and close" begin
        handler = SASLib.open("test1.sas7bdat")
        @test typeof(handler) == SASLib.Handler
        @test handler.config.filename == "test1.sas7bdat"
        @test SASLib.close(handler) == nothing
    end

    @testset "read data" begin
        files = filter(x -> endswith(x, "sas7bdat") && startswith(x, "test"), 
            Base.Filesystem.readdir())
        for f in files
            result = readsas(f)
            @test (result[:nrows], result[:ncols]) == (10, 100)
        end
    end

    @testset "incremental read" begin
        fname = "test1.sas7bdat"  # 10 rows
        handler = SASLib.open(fname)
        @test handler.config.filename == fname
        result = SASLib.read(handler, 3)  # read 3 rows
        @test result[:nrows] == 3
        result = SASLib.read(handler, 4)
        @test result[:nrows] == 4
        result = SASLib.read(handler, 5)  # should read only 3 rows even though we ask for 5
        @test result[:nrows] == 3
    end

    @testset "various data types" begin
        result = readsas("test1.sas7bdat")
        df = result[:data]
        @test sum(df[:Column1][1:5]) == 2.066
        @test count(isnan, df[:Column1]) == 1
        @test df[:Column98][1:3] == [ "apple", "dog", "pear" ]
        @test df[:Column4][1:3] == [Date("1965-12-10"), Date("1977-03-07"), Date("1983-08-15")]
    end

    @testset "datetime with missing values" begin
        result = readsas("datetime.sas7bdat")
        df = result[:data]
        @test (result[:nrows], result[:ncols]) == (5, 4)
        @test result[:data][:mtg][1] == Date(2017, 11, 24)
        @test result[:data][:dt][5] == DateTime(2018, 3, 31, 14, 20, 33)
        @test count(ismissing, result[:data][:mtg]) == 1
        @test count(ismissing, result[:data][:dt]) == 3
    end

    @testset "include/exclude columns" begin
        result = readsas("productsales.sas7bdat", include_columns=[:MONTH, :YEAR])
        @test result[:ncols] == 2
        @test sort(result[:column_symbols]) == sort([:MONTH, :YEAR])
        
        result = readsas("productsales.sas7bdat", include_columns=[1, 2, 7])
        @test result[:ncols] == 3
        @test sort(result[:column_symbols]) == sort([:ACTUAL, :PREDICT, :PRODUCT])

        result = readsas("productsales.sas7bdat", exclude_columns=[:DIVISION])
        @test result[:ncols] == 9
        @test !(:DIVISION in result[:column_symbols])

        result = readsas("productsales.sas7bdat", exclude_columns=collect(2:10))
        @test result[:ncols] == 1
        @test sort(result[:column_symbols]) == sort([:ACTUAL])

        # error handling
        @test_throws SASLib.ConfigError readsas("productsales.sas7bdat", 
            include_columns=[1], exclude_columns=[1])
    end

    @testset "misc" begin
        result = readsas("productsales.sas7bdat")
        df = result[:data]
		@test result[:ncols] == 10
		@test result[:nrows] == 1440
		@test result[:page_length] == 8192
		@test sum(df[:ACTUAL]) ≈ 730337.0
    end

	@testset "exception" begin
        @test_throws SASLib.FileFormatError readsas("runtests.jl")
	end

end
