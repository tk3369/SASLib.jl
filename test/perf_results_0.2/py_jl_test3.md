# Performance Test 3

## Summary

Julia is 4.1x faster than Python

## Test File

Filename             |Rows  |Columns|Numeric Columns|String Columns
---------------------|------|-------|---------------|--------------
productsales.sas7bdat|1440  |10     |4              |6

## Test Environment

```
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
```

## Python
```
$ python perf_test1.py productsales.sas7bdat 
1: elapsed 0.034272 seconds
2: elapsed 0.030726 seconds
3: elapsed 0.036244 seconds
4: elapsed 0.031315 seconds
5: elapsed 0.036770 seconds
6: elapsed 0.028680 seconds
7: elapsed 0.038459 seconds
8: elapsed 0.033905 seconds
9: elapsed 0.036311 seconds
10: elapsed 0.031037 seconds
Average: 0.0338 seconds
```

## Julia
```
$ julia perf_test1.jl productsales.sas7bdat 
Loaded library in 0.222 seconds
Bootstrap elapsed 2.571 seconds
Elapsed 0.007 seconds
Elapsed 0.006 seconds
Elapsed 0.007 seconds
Elapsed 0.006 seconds
Elapsed 0.007 seconds
Elapsed 0.018 seconds
Elapsed 0.008 seconds
Elapsed 0.008 seconds
Elapsed 0.007 seconds
Elapsed 0.010 seconds
Average: 0.0082903935 seconds
```
