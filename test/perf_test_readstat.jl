using SASLib
using ReadStat
using BenchmarkTools

files = [
    "data_misc/numeric_1000000_2.sas7bdat",
    "data_misc/types.sas7bdat",
    "data_AHS2013/homimp.sas7bdat",
    "data_AHS2013/omov.sas7bdat",
    "data_AHS2013/owner.sas7bdat",
    "data_AHS2013/ratiov.sas7bdat",
    "data_AHS2013/rmov.sas7bdat",
    "data_AHS2013/topical.sas7bdat",
    "data_pandas/airline.sas7bdat",
    "data_pandas/datetime.sas7bdat",
    "data_pandas/productsales.sas7bdat",
    "data_pandas/test1.sas7bdat",
    "data_pandas/test2.sas7bdat",
    "data_pandas/test3.sas7bdat",
    "data_pandas/test4.sas7bdat",
    "data_pandas/test5.sas7bdat",
    "data_pandas/test6.sas7bdat",
    "data_pandas/test7.sas7bdat",
    "data_pandas/test8.sas7bdat",
    "data_pandas/test9.sas7bdat",
    "data_pandas/test11.sas7bdat",
    "data_pandas/test10.sas7bdat",
    "data_pandas/test12.sas7bdat",
    "data_pandas/test13.sas7bdat",
    "data_pandas/test14.sas7bdat",
    "data_pandas/test15.sas7bdat",
    "data_pandas/test16.sas7bdat",
    "data_pandas/zero_variables.sas7bdat",
    "data_reikoch/barrows.sas7bdat",
    "data_reikoch/binary.sas7bdat",
    "data_reikoch/extr.sas7bdat",
    "data_reikoch/ietest2.sas7bdat"
]

for f in files
    println("\n\n================ $f =================")
    try
        println("ReadStat:")
        b1 = @benchmark read_sas7bdat($f) 
        display(b1)
        println()

        println("SASLib:")
        b2 = @benchmark readsas($f, verbose_level=0) 
        display(b2)
        println()

        println("SASLib (regular string):")
        b3 = @benchmark readsas($f, string_array_fn=Dict(:_all_ => REGULAR_STR_ARRAY), verbose_level=0) 
        display(b3)
        println()

        t1 = minimum(b1).time / 1000000
        t2 = minimum(b2).time / 1000000
        t3 = minimum(b3).time / 1000000
        p2 = round(Int, t2/t1*100)
        p3 = round(Int, t3/t1*100)
        @printf "Summary %-40s: %8.3f ms , %8.3f ms (%3d%%), %8.3f ms (%3d%%)\n" f t1 t2 p2 t3 p3
    catch
        @printf "Summary %-40s: skipped due to error condition\n" f
    finally
        flush(STDOUT)
    end

end