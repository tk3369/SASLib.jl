# Performance Test 1

## Summary

SASLib is ~4.3x faster than Pandas.

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
1: elapsed 1.976702 seconds
2: elapsed 1.984404 seconds
3: elapsed 2.266284 seconds
4: elapsed 1.978403 seconds
5: elapsed 1.946053 seconds
6: elapsed 1.919336 seconds
7: elapsed 1.918322 seconds
8: elapsed 1.926547 seconds
9: elapsed 1.962013 seconds
10: elapsed 1.939654 seconds
Average: 1.9818 seconds
```

## Julia
```
$ julia perf_test1.jl numeric_1000000_2.sas7bdat
Loaded library in 0.343 seconds
Bootstrap elapsed 4.211 seconds
Elapsed 0.481 seconds
Elapsed 0.462 seconds
Elapsed 0.414 seconds
Elapsed 0.480 seconds
Elapsed 0.473 seconds
Elapsed 0.472 seconds
Elapsed 0.473 seconds
Elapsed 0.479 seconds
Elapsed 0.401 seconds
Elapsed 0.463 seconds
Average: 0.4598392924 seconds
```
