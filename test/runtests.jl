using SASLib
using Base.Test

@testset "SASLib" begin

    @testset "getdefault" begin
        getdefault = SASLib.getdefault
        dict = Dict(:abc => 1, "b" => 2, 100 => "good")
        @test getdefault(dict, :abc, "hello") == 1
        @test getdefault(dict, "b", "hello")  == 2
        @test getdefault(dict, 100, "hello")  == "good"
        @test getdefault(dict, :x, "hello") == "hello"
        @test getdefault(dict, "y", "hello") == "hello"
        @test getdefault(dict, 200, "hello") == "hello"
    end

    @testset "openclose" begin
        handler = SASLib.openfile(SASLib.ReaderConfig("test1.sas7bdat"))
        @test typeof(handler) == SASLib.Handler
        @test SASLib.closefile(handler) == nothing
    end

    @testset "header" begin
        @test readsas("test1.sas7bdat") == 1
    end
    #nothing

end