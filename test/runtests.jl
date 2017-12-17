using SASLib
using Base.Test

@testset "SASLib" begin

    @testset "open and close" begin
        handler = SASLib.open(SASLib.ReaderConfig("test1.sas7bdat"))
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

    @testset "manual" begin
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

    @testset "numeric" begin
        result = readsas("test1.sas7bdat")
        df = result[:data]
        @test sum(df[:Column1][1:5]) == 2.066
        @test count(isnan, df[:Column1]) == 1
        @test df[:Column98][1:3] == [ "apple", "dog", "pear" ]
        @test df[:Column4][1:3] == [Date("1965-12-10"), Date("1977-03-07"), Date("1983-08-15")]
    end

end