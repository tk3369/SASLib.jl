# Performance Test 2

## Summary

SASLib is 24x faster than Pandas.

## Test File

Filename      |Rows|Columns|Numeric Columns|String Columns
--------------|----|-------|---------------|--------------
test1.sas7bdat|10  |100    |73             |27

## Python
```
$ python perf_test1.py data_pandas/test1.sas7bdat 100
Minimum: 0.0811 seconds
Median:  0.0871 seconds
Mean:    0.0890 seconds
Maximum: 0.1208 seconds
```

## Julia
```
$ julia perf_test1.jl data_pandas/test1.sas7bdat 100
Julia Version 0.6.2
Commit d386e40c17 (2017-12-13 18:08 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin14.5.0)
  CPU: Intel(R) Core(TM) i5-4258U CPU @ 2.40GHz
  WORD_SIZE: 64
  BLAS: libopenblas (USE64BITINT DYNAMIC_ARCH NO_AFFINITY Haswell)
  LAPACK: libopenblas64_
  LIBM: libopenlibm
  LLVM: libLLVM-3.9.1 (ORCJIT, haswell)

Loaded library in 0.705 seconds
BenchmarkTools.Trial: 
  memory estimate:  2.72 MiB
  allocs estimate:  35788
  --------------
  minimum time:     3.384 ms (0.00% GC)
  median time:      3.561 ms (0.00% GC)
  mean time:        4.190 ms (8.75% GC)
  maximum time:     9.082 ms (39.94% GC)
  --------------
  samples:          100
  evals/sample:     1
```
