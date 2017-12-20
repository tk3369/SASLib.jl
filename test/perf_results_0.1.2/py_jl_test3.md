# Performance Test 3

## Summary

Julia is 3.5x _slower_ than Python!

## Test File

Filename             |Rows  |Columns|Numeric Columns|String Columns
---------------------|------|-------|---------------|--------------
productsales.sas7bdat|1440  |10     |4              |6

## Test Environment

```
julia> versioninfo()
Julia Version 0.6.1
Commit 0d7248e (2017-10-24 22:15 UTC)
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
1: elapsed 0.038040 seconds
2: elapsed 0.030986 seconds
3: elapsed 0.039832 seconds
4: elapsed 0.031767 seconds
5: elapsed 0.041312 seconds
6: elapsed 0.033195 seconds
7: elapsed 0.039814 seconds
8: elapsed 0.030574 seconds
9: elapsed 0.040095 seconds
10: elapsed 0.031431 seconds
Average: 0.0357 seconds
```

## Julia
```
$ julia perf_test1.jl productsales.sas7bdat 
Loaded library in 0.212 seconds
Bootstrap elapsed 2.920 seconds
Elapsed 0.129 seconds
Elapsed 0.128 seconds
Elapsed 0.126 seconds
Elapsed 0.123 seconds
Elapsed 0.126 seconds
Elapsed 0.128 seconds
Elapsed 0.129 seconds
Elapsed 0.128 seconds
Elapsed 0.124 seconds
Elapsed 0.125 seconds
Average: 0.12677397689999997 seconds

```
