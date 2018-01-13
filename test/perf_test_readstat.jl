using SASLib
using ReadStat
using BenchmarkTools

function performtest(f, samples, seconds)
    println("\n\n================ $f =================")
    try
        println("ReadStat:")
        b1 = @benchmark read_sas7bdat($f) samples=samples seconds=seconds
        display(b1)
        println()

        println("SASLib:")
        b2 = @benchmark readsas($f, verbose_level=0) samples=samples seconds=seconds
        display(b2)
        println()

        println("SASLib (regular string):")
        b3 = @benchmark readsas($f, string_array_fn=Dict(:_all_ => REGULAR_STR_ARRAY), verbose_level=0)  samples=samples seconds=seconds
        display(b3)
        println()

        meta = readsas(f)
        ns = count(x -> x == DataType(String), meta[:column_types])
        nd = count(x -> x == DataType(Float64), meta[:column_types])
        nt = meta[:ncols] - ns - nd

        t1 = minimum(b1).time / 1000000
        t2 = minimum(b2).time / 1000000
        t3 = minimum(b3).time / 1000000
        p2 = round(Int, t2/t1*100)
        p3 = round(Int, t3/t1*100)
        comp = get(meta, :compression, "-")
        @printf "%-40s: %8.3f ms %8.3f ms (%3d%%) %8.3f ms (%3d%%) %4d %4d %4d %4s\n" f t1 t2 p2 t3 p3 nd ns nt comp
    catch
        b = " "
        @printf "%-40s: %8s ms %8s ms (%3s%%) %8s ms (%3s%%) %4s %4s %4s %4s\n" f b b b b b b b b b
    finally
        flush(STDOUT)
    end
end

@printf "%-40s: %8s    %8s    %3s    %8s    %3s   %4s %4s %4s %4s\n" "Filename" "ReadStat" "SASLib" "S/R" "SASLibA" "SA/R" "F64" "STR" "DT" "COMP"

# Tuple of (filename, # samples, # seconds)
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
    performtest(f, x, y)
end