# Performance Test 3

## Summary

SASLib is 5.2x faster than Pandas.

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
1: elapsed 0.035160 seconds
2: elapsed 0.031523 seconds
3: elapsed 0.041026 seconds
4: elapsed 0.033476 seconds
5: elapsed 0.045547 seconds
6: elapsed 0.030253 seconds
7: elapsed 0.038022 seconds
8: elapsed 0.032196 seconds
9: elapsed 0.046579 seconds
10: elapsed 0.033603 seconds
Average: 0.0367 seconds
```

## Julia
```
$ julia perf_test1.jl productsales.sas7bdat 
Loaded library in 0.328 seconds
Bootstrap elapsed 3.613 seconds
Elapsed 0.013 seconds
Elapsed 0.005 seconds
Elapsed 0.005 seconds
Elapsed 0.004 seconds
Elapsed 0.007 seconds
Elapsed 0.008 seconds
Elapsed 0.007 seconds
Elapsed 0.011 seconds
Elapsed 0.007 seconds
Elapsed 0.005 seconds
Average: 0.0071251584000000005 seconds
```
