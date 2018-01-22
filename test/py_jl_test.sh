#!/bin/sh
# Run python/julia comparison performance test

if [ $# -ne 1 ]
then
		echo "Usage: `basename $0` outputdir"
		exit 1
fi

outdir=$1
julia py_jl_test.jl data_misc/numeric_1000000_2.sas7bdat 100 $outdir
julia py_jl_test.jl data_pandas/test1.sas7bdat 100 $outdir
julia py_jl_test.jl data_pandas/productsales.sas7bdat 100 $outdir
julia py_jl_test.jl data_AHS2013/homimp.sas7bdat 50 $outdir
julia py_jl_test.jl data_AHS2013/topical.sas7bdat 30 $outdir
