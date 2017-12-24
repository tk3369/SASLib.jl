# Performance Test 1

## Summary

Julia is ~4.8x faster than Python.

## Test File

Filename|Rows|Columns|Numeric Columns|String Columns
--------|----|-------|---------------|--------------
numeric_1000000_2.sas7bdat|1,000,000|2|2|0

## Test Environment

Test system information:
```
julia> versioninfo()
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
$ python perf_test1.py numeric_1000000_2.sas7bdat
1: elapsed 1.904393 seconds
2: elapsed 1.862869 seconds
3: elapsed 1.849762 seconds
4: elapsed 1.869796 seconds
5: elapsed 1.851429 seconds
6: elapsed 1.847917 seconds
7: elapsed 1.858680 seconds
8: elapsed 1.897174 seconds
9: elapsed 1.877440 seconds
10: elapsed 1.860925 seconds
Average: 1.8680 seconds
```

## Julia
```
$ julia perf_test1.jl numeric_1000000_2.sas7bdat 
Loaded library in 2.387 seconds
Bootstrap elapsed 3.018 seconds
Elapsed 0.456 seconds
Elapsed 0.455 seconds
Elapsed 0.466 seconds
Elapsed 0.364 seconds
Elapsed 0.468 seconds
Elapsed 0.464 seconds
Elapsed 0.366 seconds
Elapsed 0.464 seconds
Elapsed 0.459 seconds
Elapsed 0.367 seconds
Average: 0.432819138 seconds
```
