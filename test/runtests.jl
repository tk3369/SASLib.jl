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
            df = readsas(f)
            @test size(df) == (10, 100)
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

end