using BenchmarkTools
using SASLib
using ReadStat

if length(ARGS) != 1
	println("Usage: julia ", PROGRAM_FILE, " <output-dir>")
	exit(1)
end

dir = ARGS[1]
if !isdir(dir) 
	println("Error: ", dir, " does not exist")
	exit(2)
end

function performtest(io, f, samples, seconds)
    println(io, "\n\n================ $f =================")
	mime = MIME("text/plain")
    try
	    info("testing $f with ReadStat")
        println(io, "ReadStat:")
        b1 = @benchmark read_sas7bdat($f) samples=samples seconds=seconds
        show(io, mime, b1)
        println(io)

	    info("testing $f with SASLib")
        println(io, "SASLib:")
        b2 = @benchmark readsas($f, verbose_level=0) samples=samples seconds=seconds
        show(io, mime, b2)
        println(io)

	    info("testing $f with SASLib regular string")
        println(io, "SASLib (regular string):")
        b3 = @benchmark readsas($f, string_array_fn=Dict(:_all_ => REGULAR_STR_ARRAY), verbose_level=0)  samples=samples seconds=seconds
        show(io, mime, b3)
        println(io)

        md = metadata(f)
        nd = count(x -> last(x) == Float64, md.columnsinfo)
        ns = count(x -> last(x) == String, md.columnsinfo)
        nt = md.ncols - ns - nd
		println("debug: meta nd=$nd ns=$ns nt=$nt")

        t1 = minimum(b1).time / 1000000
        t2 = minimum(b2).time / 1000000
        t3 = minimum(b3).time / 1000000
        p2 = round(Int, t2/t1*100)
        p3 = round(Int, t3/t1*100)
        comp = md.compression
		info("Results: ", join(string.([f,t1,t2,p2,t3,p3,nd,ns,nt,comp]), ","))
        @printf io "%-40s: %8.3f ms %8.3f ms (%3d%%) %8.3f ms (%3d%%) %4d %4d %4d %4s\n" f t1 t2 p2 t3 p3 nd ns nt comp
    catch ex
        println(ex)
        b = " "
        @printf io "%-40s: %8s ms %8s ms (%3s%%) %8s ms (%3s%%) %4s %4s %4s %4s\n" f b b b b b b b b b
    finally
        flush(io)
    end
end

open("$dir/saslib_vs_readstat.log", "w") do io
	@printf io "%-40s: %8s    %8s    %3s    %8s    %3s   %4s %4s %4s %4s\n" "Filename" "ReadStat" "SASLib" "S/R" "SASLibA" "SA/R" "F64" "STR" "DT" "COMP"
	files = [
		("data_pandas/test3.sas7bdat", 10000, 5),
		("data_misc/numeric_1000000_2.sas7bdat", 100, 5),
		("data_misc/types.sas7bdat", 10000, 5),
		("data_AHS2013/homimp.sas7bdat", 10000, 5),
		("data_AHS2013/omov.sas7bdat", 10000, 5),
		("data_AHS2013/owner.sas7bdat", 10000, 5),
        ("data_AHS2013/ratiov.sas7bdat", 10000,5),
        ("data_AHS2013/rmov.sas7bdat", 10000, 5),
        ("data_AHS2013/topical.sas7bdat", 10000, 30),
        ("data_pandas/airline.sas7bdat", 10000, 5),
        ("data_pandas/datetime.sas7bdat", 10000, 5),
        ("data_pandas/productsales.sas7bdat", 10000, 10),
        ("data_pandas/test1.sas7bdat", 10000, 5),
        ("data_pandas/test2.sas7bdat", 10000, 5),
        ("data_pandas/test4.sas7bdat", 10000, 5),
        ("data_pandas/test5.sas7bdat", 10000, 5),
        ("data_pandas/test6.sas7bdat", 10000, 5),
        ("data_pandas/test7.sas7bdat", 10000, 5),
        ("data_pandas/test8.sas7bdat", 10000, 5),
        ("data_pandas/test9.sas7bdat", 10000, 5),
        ("data_pandas/test11.sas7bdat", 10000, 5),
        ("data_pandas/test10.sas7bdat", 10000, 5),
        ("data_pandas/test12.sas7bdat", 10000, 5),
        ("data_pandas/test13.sas7bdat", 10000, 5),
        ("data_pandas/test14.sas7bdat", 10000, 5),
        ("data_pandas/test15.sas7bdat", 10000, 5),
        ("data_pandas/test16.sas7bdat", 10000, 5),
        ("data_pandas/zero_variables.sas7bdat", 10000, 5),
        ("data_reikoch/barrows.sas7bdat", 10000, 5),
        ("data_reikoch/binary.sas7bdat", 10000, 5),
        ("data_reikoch/extr.sas7bdat", 10000, 5),
        ("data_reikoch/ietest2.sas7bdat", 10000, 5),
    ]
    for (f, x, y) in files
        performtest(io, f, x, y)
    end

end
