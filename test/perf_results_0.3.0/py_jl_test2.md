# Performance Test 2

## Summary

SASLib is 16.9x faster than Pandas.

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
1: elapsed 0.099821 seconds
2: elapsed 0.116454 seconds
3: elapsed 0.095141 seconds
4: elapsed 0.100083 seconds
5: elapsed 0.100060 seconds
6: elapsed 0.098249 seconds
7: elapsed 0.101819 seconds
8: elapsed 0.099673 seconds
9: elapsed 0.096865 seconds
10: elapsed 0.109412 seconds
Average: 0.1018 seconds
```

## Julia
```
$ julia perf_test1.jl test1.sas7bdat 
Loaded library in 0.326 seconds
Bootstrap elapsed 3.606 seconds
Elapsed 0.011 seconds
Elapsed 0.004 seconds
Elapsed 0.004 seconds
Elapsed 0.004 seconds
Elapsed 0.004 seconds
Elapsed 0.004 seconds
Elapsed 0.010 seconds
Elapsed 0.013 seconds
Elapsed 0.004 seconds
Elapsed 0.004 seconds
Average: 0.0060341937 seconds
```
