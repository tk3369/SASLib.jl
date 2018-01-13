# Performance Test 1

## Summary

SASLib is ~12x faster than Pandas.

## Test File

Filename|Rows|Columns|Numeric Columns|String Columns
--------|----|-------|---------------|--------------
numeric_1000000_2.sas7bdat|1,000,000|2|2|0

## Python
```
$ python -V
Python 3.6.3 :: Anaconda custom (64-bit)
$ python perf_test1.py data_misc/numeric_1000000_2.sas7bdat 30
Minimum: 1.8377 seconds
Median:  1.9093 seconds
Mean:    1.9168 seconds
Maximum: 2.0423 seconds
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

Loaded library in 0.656 seconds
BenchmarkTools.Trial: 
  memory estimate:  153.16 MiB
  allocs estimate:  1002726
  --------------
  minimum time:     151.382 ms (3.41% GC)
  median time:      235.003 ms (35.13% GC)
  mean time:        202.453 ms (23.83% GC)
  maximum time:     272.253 ms (35.25% GC)
  --------------
  samples:          25
  evals/sample:     1
```


