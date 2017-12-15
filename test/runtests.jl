using SASLib
using Base.Test

@testset "SASLib" begin

    @testset "open and close" begin
        handler = SASLib.openfile(SASLib.ReaderConfig("test1.sas7bdat"))
        @test typeof(handler) == SASLib.Handler
        @test SASLib.closefile(handler) == nothing
    end

    @testset "read data" begin
        files = filter(x -> endswith(x, "sas7bdat") && startswith(x, "test"), 
            Base.Filesystem.readdir())
        for f in files
            df = readsas(f)
            @test size(df) == (10, 100)
        end
    end

end