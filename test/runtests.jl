using SASLib, Missings
using Base.Test

function getpath(dir, file) 
    path = "$dir/$file"
    #println("================ $path ================")
    path
end
readfile(dir, file)  = readsas(getpath(dir, file))
openfile(dir, file)  = SASLib.open(getpath(dir, file))

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
            @test (result[:nrows], result[:ncols]) == (10, 100)
        end
    end

    @testset "incremental read" begin
        handler = openfile("data_pandas", "test1.sas7bdat")
        @test handler.config.filename == "data_pandas/test1.sas7bdat"
        result = SASLib.read(handler, 3)  # read 3 rows
        @test result[:nrows] == 3
        result = SASLib.read(handler, 4)  # read 4 rows
        @test result[:nrows] == 4
        result = SASLib.read(handler, 5)  # should read only 3 rows even though we ask for 5
        @test result[:nrows] == 3
    end

    @testset "various data types" begin
        result = readfile("data_pandas", "test1.sas7bdat")
        df = result[:data]
        @test sum(df[:Column1][1:5]) == 2.066
        @test count(isnan, df[:Column1]) == 1
        @test df[:Column98][1:3] == [ "apple", "dog", "pear" ]
        @test df[:Column4][1:3] == [Date("1965-12-10"), Date("1977-03-07"), Date("1983-08-15")]
    end

    @testset "datetime with missing values" begin
        result = readfile("data_pandas", "datetime.sas7bdat")
        df = result[:data]
        @test (result[:nrows], result[:ncols]) == (5, 4)
        @test result[:data][:mtg][1] == Date(2017, 11, 24)
        @test result[:data][:dt][5] == DateTime(2018, 3, 31, 14, 20, 33)
        @test count(ismissing, result[:data][:mtg]) == 1
        @test count(ismissing, result[:data][:dt]) == 3
    end

    @testset "include/exclude columns" begin
        fname = getpath("data_pandas", "productsales.sas7bdat")

        result = readsas(fname, include_columns=[:MONTH, :YEAR])
        @test result[:ncols] == 2
        @test sort(result[:column_symbols]) == sort([:MONTH, :YEAR])
        
        result = readsas(fname, include_columns=[1, 2, 7])
        @test result[:ncols] == 3
        @test sort(result[:column_symbols]) == sort([:ACTUAL, :PREDICT, :PRODUCT])

        result = readsas(fname, exclude_columns=[:DIVISION])
        @test result[:ncols] == 9
        @test !(:DIVISION in result[:column_symbols])

        result = readsas(fname, exclude_columns=collect(2:10))
        @test result[:ncols] == 1
        @test sort(result[:column_symbols]) == sort([:ACTUAL])

        # error handling
        @test_throws SASLib.ConfigError readsas(fname, 
            include_columns=[1], exclude_columns=[1])
    end

    @testset "misc" begin
        result = readfile("data_pandas", "productsales.sas7bdat")
        df = result[:data]
		@test result[:ncols] == 10
		@test result[:nrows] == 1440
		@test result[:page_length] == 8192
		@test sum(df[:ACTUAL]) ≈ 730337.0
    end

    @testset "stat_transfer" begin
        result = readfile("data_misc", "types.sas7bdat")
        df = result[:data]
        @test sum(df[:vbyte][1:2])   == 9
        @test sum(df[:vint][1:2])    == 9
        @test sum(df[:vlong][1:2])   == 9
        @test sum(df[:vfloat][1:2])  ≈  10.14000010
        @test sum(df[:vdouble][1:2]) ≈  10.14000000
    end

    # topical.sas7bdat contains columns labels which should be ignored anywas
    @testset "AHS2013" begin
        handler = openfile("data_AHS2013", "topical.sas7bdat")
        result = SASLib.read(handler, 1000)
        SASLib.close(handler)
        df = result[:data]
		@test result[:ncols] == 114
		@test result[:nrows] == 1000
		@test result[:page_count] == 10
        @test result[:page_length] == 16384
        @test result[:system_endianness] == :LittleEndian
        @test count(x -> x == "B", df[:DPEVVEHIC]) == 648
        @test mean(filter(!isnan, df[:PTCOSTGAS])) ≈ 255.51543209876544
    end

    @testset "file encoding" begin
        result = readfile("data_reikoch", "extr.sas7bdat")
        df = result[:data]
        @test result[:file_encoding] == "CP932"
        @test df[:AETXT][1] == "眠気"
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
        
        result = readsas("data_AHS2013/homimp.sas7bdat")
        @test typeof(result[:data][:RAS]) == SASLib.ObjectPool{String,UInt16}

        result = readsas("data_AHS2013/homimp.sas7bdat", 
            string_array_fn = Dict(:RAS => REGULAR_STR_ARRAY))
        @test typeof(result[:data][:RAS]) == Array{String,1}
    end

    @testset "just reads" begin
        for dir in ["data_pandas", "data_reikoch", "data_AHS2013", "data_misc"]
            for f in readdir(dir)
                if endswith(f, ".sas7bdat") && 
                        !(f in ["zero_variables.sas7bdat"])
                    result = readfile(dir, f)
                    @test result[:nrows] > 0
                end
            end
        end
    end

	@testset "exception" begin
        @test_throws SASLib.FileFormatError readsas("runtests.jl")
	end

end
