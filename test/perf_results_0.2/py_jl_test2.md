# Performance Test 2

## Summary

Julia is 7.6x faster than Python.

## Test File

Filename      |Rows|Columns|Numeric Columns|String Columns
--------------|----|-------|---------------|--------------
test1.sas7bdat|10  |100    |73             |27

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
$ python perf_test1.py test1.sas7bdat 
1: elapsed 0.160085 seconds
2: elapsed 0.102635 seconds
3: elapsed 0.106069 seconds
4: elapsed 0.099819 seconds
5: elapsed 0.097443 seconds
6: elapsed 0.096373 seconds
7: elapsed 0.104192 seconds
8: elapsed 0.096230 seconds
9: elapsed 0.103648 seconds
10: elapsed 0.099993 seconds
Average: 0.1066 seconds
```

## Julia
```
$ julia perf_test1.jl test1.sas7bdat 
Loaded library in 0.233 seconds
Bootstrap elapsed 2.821 seconds
Elapsed 0.011 seconds
Elapsed 0.010 seconds
Elapsed 0.011 seconds
Elapsed 0.017 seconds
Elapsed 0.022 seconds
Elapsed 0.012 seconds
Elapsed 0.012 seconds
Elapsed 0.014 seconds
Elapsed 0.010 seconds
Elapsed 0.021 seconds
Average: 0.013979034499999998 seconds
```
