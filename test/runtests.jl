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
            @test size(result.dataframe) == (10, 100)
        end
    end

    @testset "manual" begin
        fname = "test1.sas7bdat"  # 10 rows
        handler = SASLib.open(fname)
        @test handler.config.filename == fname
        r = SASLib.read(handler, 3)  # read 3 rows
        @test size(r, 1) == 3
        r = SASLib.read(handler, 4)
        @test size(r, 1) == 4
        r = SASLib.read(handler, 5)  # should read only 3 rows even though we ask for 5
        @test size(r, 1) == 3
    end

    @testset "numeric" begin
        result = readsas("test1.sas7bdat")
        df = result.dataframe
        @test sum(df[1:5,1]) == 2.066
        @test count(isnan, df[:,1]) == 1
        @test df[1:3,98] == [ "apple", "dog", "pear" ]
        @test df[1:3,4] == [Date("1965-12-10"), Date("1977-03-07"), Date("1983-08-15")]
    end

end