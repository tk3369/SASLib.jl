using SASLib, Missings
using Compat.Test, Compat.Dates, Compat.Distributed, Compat.SharedArrays, Compat

function getpath(dir, file) 
    path = "$dir/$file"
    #println("================ $path ================")
    path
end
readfile(dir, file; kwargs...)  = readsas(getpath(dir, file); kwargs...)
openfile(dir, file; kwargs...)  = SASLib.open(getpath(dir, file), kwargs...)

@testset "SASLib" begin

    @testset "object pool" begin
        println("Testing object pool...")

        # string pool
        default = ""
        x = SASLib.ObjectPool{String, UInt8}(default, 5)
        @test length(x) == 5
        @test size(x) == (5, )
        @test endof(x) == 5
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

    @testset "open and close" begin
        handler = openfile("data_pandas", "test1.sas7bdat")
        @test typeof(handler) == SASLib.Handler
        @test handler.config.filename == "data_pandas/test1.sas7bdat"
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
        @test handler.config.filename == "data_pandas/test1.sas7bdat"
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
        @static if VERSION.minor < 7
            @test_warn "Unknown include column" readsas(fname, include_columns=[:blah, :Year])
            @test_warn "Unknown exclude column" readsas(fname, exclude_columns=[:blah, :Year])
        else
            Compat.Test.@test_logs (:warn, "Unknown include column blah") (:warn, 
                "Unknown include column Year") readsas(fname, include_columns=[:blah, :Year])
            Compat.Test.@test_logs (:warn, "Unknown exclude column blah") (:warn, 
                "Unknown exclude column Year") readsas(fname, exclude_columns=[:blah, :Year])
        end
        # error handling
        @test_throws SASLib.ConfigError readsas(fname, 
            include_columns=[1], exclude_columns=[1])
    end

    @testset "misc" begin
        rs = readfile("data_pandas", "productsales.sas7bdat")
		@test size(rs) == (1440, 10)
#		@test result[:page_length] == 8192
		@test sum(rs[:ACTUAL]) ≈ 730337.0
        handler = openfile("data_AHS2013", "topical.sas7bdat")
        @test show(handler) == nothing
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
        SASLib.close(handler)
		@test size(rs) == (1000, 114)
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
        
        rs = readsas("data_AHS2013/homimp.sas7bdat")
        @test typeof(rs[:RAS]) == SASLib.ObjectPool{String,UInt16}

        # string_array_fn test for specific string columns
        rs = readsas("data_AHS2013/homimp.sas7bdat", 
            string_array_fn = Dict(:RAS => REGULAR_STR_ARRAY))
        @test typeof(rs[:RAS]) == Array{String,1}
        @test typeof(rs[:RAH]) != Array{String,1}

        # string_array_fn test for all string columns
        rs = readsas("data_AHS2013/homimp.sas7bdat", 
            string_array_fn = Dict(:_all_ => REGULAR_STR_ARRAY))
        @test typeof(rs[:RAS])     == Array{String,1}
        @test typeof(rs[:RAH])     == Array{String,1}
        @test typeof(rs[:JRAS])    == Array{String,1}
        @test typeof(rs[:JRAD])    == Array{String,1}
        @test typeof(rs[:CONTROL]) == Array{String,1}

        # number_array_fn test by column name
        makesharedarray(n) = SharedArray{Float64}(n)
        rs = readsas("data_misc/numeric_1000000_2.sas7bdat", 
            number_array_fn = Dict(:f => makesharedarray))
        @test typeof(rs[:f]) == SharedArray{Float64,1}
        @test typeof(rs[:x]) == Array{Float64,1}

        # number_array_fn test for all numeric columns
        rs = readsas("data_misc/numeric_1000000_2.sas7bdat", 
        number_array_fn = Dict(:_all_ => makesharedarray))
        @test typeof(rs[:f]) == SharedArray{Float64,1}
        @test typeof(rs[:x]) == SharedArray{Float64,1}

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
