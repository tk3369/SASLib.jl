# Performance Test 1

## Summary

Python is approximately 10% faster than the Julia implementation.

## Test File

Filename|Rows|Columns|Numeric Columns|String Columns
--------|----|-------|---------------|--------------
numeric_1000000_2.sas7bdat|1,000,000|2|2|0

## Test Environment

Test system information:
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
$ python perf_test1.py numeric_1000000_2.sas7bdat 
1: elapsed 1.844023 seconds
2: elapsed 1.806474 seconds
3: elapsed 1.795621 seconds
4: elapsed 1.812769 seconds
5: elapsed 1.850064 seconds
6: elapsed 1.882453 seconds
7: elapsed 1.863802 seconds
8: elapsed 1.871220 seconds
9: elapsed 1.874004 seconds
10: elapsed 1.861223 seconds
Average: 1.8462 seconds
```

## Julia
```
$ julia perf_test1.jl numeric_1000000_2.sas7bdat 
Loaded library in 0.225 seconds
Bootstrap elapsed 4.569 seconds
Elapsed 2.133 seconds
Elapsed 2.107 seconds
Elapsed 2.146 seconds
Elapsed 1.995 seconds
Elapsed 2.072 seconds
Elapsed 2.103 seconds
Elapsed 2.040 seconds
Elapsed 2.082 seconds
Elapsed 2.070 seconds
Elapsed 2.013 seconds
Average: 2.076054688 seconds
```
