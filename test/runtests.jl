using SASLib
using Base.Test

@testset "SASLib" begin

    @testset "open and close" begin
        handler = SASLib.openfile(SASLib.ReaderConfig("test1.sas7bdat"))
        @test typeof(handler) == SASLib.Handler
        @test SASLib.closefile(handler) == nothing
    end

    @testset "read data" begin
        df = readsas("test1.sas7bdat")
        @test size(df) == (10, 100)
    end

end