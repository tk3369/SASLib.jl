# Performance Test 2

## Summary

Julia is 8x faster than Python!

## Test File

Filename      |Rows|Columns|Numeric Columns|String Columns
--------------|----|-------|---------------|--------------
test1.sas7bdat|10  |100    |73             |27

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
$ python perf_test1.py test1.sas7bdat
1: elapsed 0.127801 seconds
2: elapsed 0.104040 seconds
3: elapsed 0.115647 seconds
4: elapsed 0.102978 seconds
5: elapsed 0.100335 seconds
6: elapsed 0.101916 seconds
7: elapsed 0.099474 seconds
8: elapsed 0.097988 seconds
9: elapsed 0.102512 seconds
10: elapsed 0.097088 seconds
Average: 0.1050 seconds
```

## Julia
```
$ julia perf_test1.jl test1.sas7bdat 
Loaded library in 0.224 seconds
Bootstrap elapsed 2.829 seconds
Elapsed 0.010 seconds
Elapsed 0.017 seconds
Elapsed 0.011 seconds
Elapsed 0.015 seconds
Elapsed 0.010 seconds
Elapsed 0.010 seconds
Elapsed 0.014 seconds
Elapsed 0.024 seconds
Elapsed 0.009 seconds
Elapsed 0.012 seconds
Average: 0.0131050582 seconds
```
