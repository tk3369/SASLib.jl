# Performance Test 1

## Summary

SASLib is ~11x faster than Pandas.

## Test File

Filename|Rows|Columns|Numeric Columns|String Columns
--------|----|-------|---------------|--------------
numeric_1000000_2.sas7bdat|1,000,000|2|2|0

## Python
```
$ python perf_test1.py data_misc/numeric_1000000_2.sas7bdat 30
Minimum: 1.8642 seconds
Median:  2.0716 seconds
Mean:    2.1451 seconds
Maximum: 2.7522 seconds
```

## Julia
```
$ julia perf_test1.jl data_misc/numeric_1000000_2.sas7bdat 30
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

Loaded library in 0.655 seconds
BenchmarkTools.Trial: 
  memory estimate:  155.12 MiB
  allocs estimate:  1035407
  --------------
  minimum time:     161.779 ms (3.74% GC)
  median time:      211.446 ms (22.19% GC)
  mean time:        211.389 ms (22.93% GC)
  maximum time:     259.749 ms (34.46% GC)
  --------------
  samples:          24
  evals/sample:     1

```
