using SASLib, Missings
using Compat.Test, Compat.Dates, Compat.Distributed, Compat.SharedArrays, Compat

@static if VERSION > v"0.7-"
    import Statistics: mean
end

function getpath(dir, file) 
    path = joinpath(dir, file)
    #println("================ $path ================")
    path
end
readfile(dir, file; kwargs...)  = readsas(getpath(dir, file); kwargs...)
openfile(dir, file; kwargs...)  = SASLib.open(getpath(dir, file), kwargs...)
getmetadata(dir, file; kwargs...) = metadata(getpath(dir, file), kwargs...)

# Struct used for column type conversion test case below
struct YearStr year::String end
Base.convert(::Type{YearStr}, v::Float64) = YearStr(string(round(Int, v)))

@testset "SASLib" begin

    @testset "object pool" begin
        println("Testing object pool...")

        # string pool
        default = ""
        x = SASLib.ObjectPool{String, UInt8}(default, 5)
        @test length(x) == 5
        @test size(x) == (5, )
        @test @compat lastindex(x) == 5
        @test count(v -> v == default, x) == 5
        @test count(v -> v === default, x) == 5
        @test map(v -> "x$v", x) == [ "x", "x", "x", "x", "x" ]
        x[1] = "abc"
        @test x[1] == "abc"
        @test x.uniqueitemscount == 2
        x[2] = "abc"
        @test x[2] == "abc"
        @test x.uniqueitemscount == 2
        x[3] = "xyz"
        @test x.uniqueitemscount == 3
        @test x.itemscount == 5
        @test_throws BoundsError x[6] == ""

        # tuple pool
        y = SASLib.ObjectPool{Tuple, UInt8}((1,1,1), 100)
        y[1:100] = [(v, v, v) for v in 1:100]
        @test y[1] == (1,1,1)
        @test y[2] == (2,2,2)
        @test y[100] == (100,100,100)
        @test y.uniqueitemscount == 100   # first one is the same as the default

        # more error conditions
        z = SASLib.ObjectPool{Int, UInt8}(0, 1000)
        @test_throws BoundsError z[1:300] = 1:300
    end

    @testset "case insensitive dict" begin
        function testdict(lowercase_key, mixedcase_key, second_lowercase_key) 

            T = typeof(lowercase_key)
            d = SASLib.CIDict{T,Int}()

            # getindex/setindex!
            d[lowercase_key] = 99
            @test d[lowercase_key] == 99
            @test d[mixedcase_key] == 99
            d[mixedcase_key] = 88           # should replace original value
            @test length(d) == 1            # still 1 element
            @test d[lowercase_key] == 88
            @test d[mixedcase_key] == 88

            # haskey
            @test haskey(d, lowercase_key) == true
            @test haskey(d, mixedcase_key) == true

            # iteration
            d[second_lowercase_key] = 77
            ks = T[]
            vs = Int[]
            for (k,v) in d
                push!(ks, k)
                push!(vs, v)
            end
            @test ks == [lowercase_key, second_lowercase_key]
            @test vs == [88, 77]

            # keys/values
            @test collect(keys(d)) == [lowercase_key, second_lowercase_key]
            @test collect(values(d)) == [88, 77]

            # show
            @test show(d) == nothing
        end
        testdict(:abc, :ABC, :def)
        testdict("abc", "ABC", "def")
    end

    @testset "open and close" begin
        handler = openfile("data_pandas", "test1.sas7bdat")
        @test typeof(handler) == SASLib.Handler
        @test handler.config.filename == getpath("data_pandas", "test1.sas7bdat")
        @test SASLib.close(handler) == nothing
    end

    @testset "read basic test files (test*.sas7bdat)" begin
        dir = "data_pandas"
        files = filter(x -> endswith(x, "sas7bdat") && startswith(x, "test"), 
            Base.Filesystem.readdir("$dir"))
        for f in files
            result = readfile(dir, f)
            @test size(result) == (10, 100)
        end
    end

    @testset "incremental read" begin
        handler = openfile("data_pandas", "test1.sas7bdat")
        @test handler.config.filename == getpath("data_pandas", "test1.sas7bdat")
        result = SASLib.read(handler, 3)  # read 3 rows
        @test size(result, 1) == 3
        result = SASLib.read(handler, 4)  # read 4 rows
        @test size(result, 1) == 4
        result = SASLib.read(handler, 5)  # should read only 3 rows even though we ask for 5
        @test size(result, 1)  == 3
    end

    @testset "various data types" begin
        rs = readfile("data_pandas", "test1.sas7bdat")
        @test sum(rs[:Column1][1:5]) == 2.066
        @test count(isnan, rs[:Column1]) == 1
        @test rs[:Column98][1:3] == [ "apple", "dog", "pear" ]
        @test rs[:Column4][1:3] == [Date("1965-12-10"), Date("1977-03-07"), Date("1983-08-15")]
    end

    @testset "datetime with missing values" begin
        rs = readfile("data_pandas", "datetime.sas7bdat")
        @test size(rs) == (5, 4)
        @test rs[:mtg][1] == Date(2017, 11, 24)
        @test rs[:dt][5] == DateTime(2018, 3, 31, 14, 20, 33)
        @test count(ismissing, rs[:mtg]) == 1
        @test count(ismissing, rs[:dt]) == 3
    end

    @testset "include/exclude columns" begin
        fname = getpath("data_pandas", "productsales.sas7bdat")

        rs = readsas(fname, include_columns=[:MONTH, :YEAR])
        @test size(rs, 2) == 2
        @test sort(names(rs)) == sort([:MONTH, :YEAR])
        
        rs = readsas(fname, include_columns=[1, 2, 7])
        @test size(rs, 2) == 3
        @test sort(names(rs)) == sort([:ACTUAL, :PREDICT, :PRODUCT])

        rs = readsas(fname, exclude_columns=[:DIVISION])
        @test size(rs, 2) == 9
        @test !(:DIVISION in names(rs))

        rs = readsas(fname, exclude_columns=collect(2:10))
        @test size(rs, 2) == 1
        @test sort(names(rs)) == sort([:ACTUAL])

        # case insensitive include/exclude
        rs = readsas(fname, include_columns=[:month, :Year])
        @test size(rs, 2) == 2
        rs = readsas(fname, exclude_columns=[:diVisiON])
        @test size(rs, 2) == 9

        # test bad include/exclude param
        # see https://discourse.julialang.org/t/test-warn-doesnt-work-with-warn-in-0-7/9001
        @static if VERSION > v"0.7-"
            Compat.Test.@test_logs (:warn, "Unknown include column blah") (:warn, 
                "Unknown include column Year") readsas(fname, include_columns=[:blah, :Year])
            Compat.Test.@test_logs (:warn, "Unknown exclude column blah") (:warn, 
                "Unknown exclude column Year") readsas(fname, exclude_columns=[:blah, :Year])
        else
            @test_warn "Unknown include column" readsas(fname, include_columns=[:blah, :Year])
            @test_warn "Unknown exclude column" readsas(fname, exclude_columns=[:blah, :Year])
        end
        # error handling
        @test_throws SASLib.ConfigError readsas(fname, 
            include_columns=[1], exclude_columns=[1])
    end

    @testset "ResultSet" begin
        rs = readfile("data_pandas", "productsales.sas7bdat")

        # metadata for result set
        @test size(rs) == (1440, 10)
        @test size(rs,1) == 1440
        @test size(rs,2) == 10
        @test length(columns(rs)) == 10 
        @test length(names(rs)) == 10 

        # cell indexing
        @test rs[1][1] ≈ 925.0
        @test rs[1,1] ≈ 925.0
        @test rs[1,:ACTUAL] ≈ 925.0

        # row/column indexing
        @test typeof(rs[1]) == Tuple{Float64,Float64,String,String,String,String,String,Float64,Float64,Date}
        @test typeof(rs[:ACTUAL]) == Array{Float64,1}
        @test sum(rs[:ACTUAL]) ≈ 730337.0

        # iteration
        @test sum(r[1] for r in rs) ≈ 730337.0
        
        # portion of result set
        @test typeof(rs[1:2]) == SASLib.ResultSet
        @test typeof(rs[:ACTUAL, :PREDICT]) == SASLib.ResultSet
        @test rs[1:2][1][1] ≈ 925.0
        @test rs[:ACTUAL, :PREDICT][1][1] ≈ 925.0

        # setindex!
        rs[1,1] = 100.0
        @test rs[1,1] ≈ 100.0
        rs[1,:ACTUAL] = 200.0
        @test rs[1,:ACTUAL] ≈ 200.0

        # display related
        @test show(rs) == nothing
        @test SASLib.sizestr(rs) == "1440 rows x 10 columns"
    end

    @testset "metadata" begin
        md = getmetadata("data_pandas", "test1.sas7bdat")
        @test md.filename == getpath("data_pandas", "test1.sas7bdat")
        @test md.encoding == "WINDOWS-1252"
        @test md.endianness == :LittleEndian
        @test md.compression == :none
        @test md.pagesize == 65536
        @test md.npages == 1
        @test md.nrows == 10
        @test md.ncols == 100
        @test length(md.columnsinfo) == 100
        @test md.columnsinfo[1] == Pair(:Column1, Float64)

        md = getmetadata("data_pandas", "productsales.sas7bdat")
        @test show(md) == nothing
        println()

        # Deal with v0.6/v0.7 difference
        # v0.6 shows Missings.Missing
        # v0.7 shows Missing
        ty(x) = replace(x, "Missings." => "")   

        # convenient comparison routine since v0.6/v0.7 displays different order
        same(x,y) = sort(ty.(string.(collect(x)))) == sort(ty.(string.(collect(y))))

        @test same(SASLib.typesof(Int64), (Int64,))
        @test same(SASLib.typesof(Union{Int64,Int32}), (Int64,Int32))
        @test same(SASLib.typesof(Union{Int64,Int32,Missings.Missing}),
            (Int64,Int32,Missings.Missing))

        @test SASLib.typesfmt((Int64,)) == "Int64"
        @test SASLib.typesfmt((Int64,Int32)) == "Int64/Int32"
        @test ty(SASLib.typesfmt((Int64,Int32,Missings.Missing))) == "Int64/Int32/Missing"
        @test SASLib.typesfmt((Int64,Int32); excludemissing=true) == "Int64/Int32"
        @test SASLib.typesfmt((Int64,Int32,Missings.Missing); excludemissing=true) == "Int64/Int32"
        @test SASLib.colfmt(md)[1] == "ACTUAL(Float64)"
    end

    @testset "stat_transfer" begin
        rs = readfile("data_misc", "types.sas7bdat")
        @test sum(rs[:vbyte][1:2])   == 9
        @test sum(rs[:vint][1:2])    == 9
        @test sum(rs[:vlong][1:2])   == 9
        @test sum(rs[:vfloat][1:2])  ≈  10.14000010
        @test sum(rs[:vdouble][1:2]) ≈  10.14000000
    end

    # topical.sas7bdat contains columns labels which should be ignored anywas
    @testset "AHS2013" begin
        handler = openfile("data_AHS2013", "topical.sas7bdat")
        rs = SASLib.read(handler, 1000)
        @test size(rs) == (1000, 114)
        @test show(handler) == nothing
        SASLib.close(handler)
		# @test result[:page_count] == 10
        # @test result[:page_length] == 16384
        # @test result[:system_endianness] == :LittleEndian
        @test count(x -> x == "B", rs[:DPEVVEHIC]) == 648
        @test mean(filter(!isnan, rs[:PTCOSTGAS])) ≈ 255.51543209876544
    end

    @testset "file encodings" begin
        rs = readfile("data_reikoch", "extr.sas7bdat")
        # @test result[:file_encoding] == "CP932"
        @test rs[:AETXT][1] == "眠気"

        rs = readfile("data_pandas", "test1.sas7bdat", encoding = "US-ASCII")
        # @test result[:file_encoding] == "US-ASCII"
        @test rs[:Column42][3] == "dog"
    end

    @testset "handler object" begin
        handler = openfile("data_reikoch", "binary.sas7bdat")
        @test handler.U64 == true
        @test handler.byte_swap == true
        @test handler.column_data_lengths == [8,8,8,8,8,8,8,8,8,8,14]
        @test handler.column_data_offsets == [0,8,16,24,32,40,48,56,64,72,80]
        @test handler.column_names == ["I","I1","I2","I3","I4","I5","I6","I7","I8","I9","CHAR"]
        @test handler.column_symbols == [:I,:I1,:I2,:I3,:I4,:I5,:I6,:I7,:I8,:I9,:CHAR]
        @test handler.compression == 0x02
        @test handler.file_encoding == "ISO-8859-1"
        @test handler.file_endianness == :BigEndian
        @test handler.header_length == 8192
        @test handler.page_length == 8192
        @test handler.row_count == 100
        @test handler.vendor == 0x01
        @test handler.config.convert_dates == true
        @test handler.config.include_columns == []
        @test handler.config.exclude_columns == []
        @test handler.config.encoding == ""
    end

    @testset "array constructors" begin
        
        rs = readfile("data_AHS2013", "homimp.sas7bdat")
        @test typeof(rs[:RAS]) == SASLib.ObjectPool{String,UInt16}

        # string_array_fn test for specific string columns
        rs = readfile("data_AHS2013", "homimp.sas7bdat", 
            string_array_fn = Dict(:RAS => REGULAR_STR_ARRAY))
        @test typeof(rs[:RAS]) == Array{String,1}
        @test typeof(rs[:RAH]) != Array{String,1}

        # string_array_fn test for all string columns
        rs = readfile("data_AHS2013", "homimp.sas7bdat", 
            string_array_fn = Dict(:_all_ => REGULAR_STR_ARRAY))
        @test typeof(rs[:RAS])     == Array{String,1}
        @test typeof(rs[:RAH])     == Array{String,1}
        @test typeof(rs[:JRAS])    == Array{String,1}
        @test typeof(rs[:JRAD])    == Array{String,1}
        @test typeof(rs[:CONTROL]) == Array{String,1}

        # number_array_fn test by column name
        makesharedarray(n) = SharedArray{Float64}(n)
        rs = readfile("data_misc", "numeric_1000000_2.sas7bdat", 
            number_array_fn = Dict(:f => makesharedarray))
        @test typeof(rs[:f]) == SharedArray{Float64,1}
        @test typeof(rs[:x]) == Array{Float64,1}

        # number_array_fn test for all numeric columns
        rs = readfile("data_misc", "numeric_1000000_2.sas7bdat", 
        number_array_fn = Dict(:_all_ => makesharedarray))
        @test typeof(rs[:f]) == SharedArray{Float64,1}
        @test typeof(rs[:x]) == SharedArray{Float64,1}

    end

    # column type conversion
    @testset "user specified column types" begin

        # normal use case
        rs = readfile("data_pandas", "productsales.sas7bdat"; 
            verbose_level = 0, column_types = Dict(:YEAR => Int16, :QUARTER => Int8))
        @test eltype(rs[:YEAR]) == Int16
        @test eltype(rs[:QUARTER]) == Int8

        # error handling - warn() when a column cannot be converted
        rs = readfile("data_pandas", "productsales.sas7bdat"; 
            verbose_level = 0, column_types = Dict(:YEAR => Int8, :QUARTER => Int8))
        @test eltype(rs[:YEAR]) == Float64
        @test eltype(rs[:QUARTER]) == Int8
        #TODO expect warning for :YEAR conversion

        # case insensitive column symbol
        rs = readfile("data_pandas", "productsales.sas7bdat"; 
            verbose_level = 0, column_types = Dict(:Quarter => Int8))
        @test eltype(rs[:QUARTER]) == Int8

        # conversion to custom types
        rs = readfile("data_pandas", "productsales.sas7bdat"; 
            verbose_level = 0, column_types = Dict(:Year => YearStr))
        @test eltype(rs[:YEAR]) == YearStr

        # test Union type
        let T = Union{Int,Missing} 
            rs = readfile("data_pandas", "productsales.sas7bdat"; 
                verbose_level = 0, column_types = Dict(:Year => T))
            @test eltype(rs[:YEAR]) == T
        end
    end

    # see output; keep this for coverage reason
    @testset "verbosity" begin
        rs = readfile("data_pandas", "test1.sas7bdat"; verbose_level = 2)
        @test size(rs, 1) > 0
    end

    @testset "just reads" begin
        for dir in ["data_pandas", "data_reikoch", "data_AHS2013", "data_misc"]
            for f in readdir(dir)
                if endswith(f, ".sas7bdat") && 
                        !(f in ["zero_variables.sas7bdat"])
                    rs = readfile(dir, f)
                    @test size(rs, 1) > 0
                end
            end
        end
    end

	@testset "exception" begin
        @test_throws SASLib.FileFormatError readsas("runtests.jl")
	end

end
