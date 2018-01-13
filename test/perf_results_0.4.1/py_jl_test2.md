# Performance Test 2

## Summary

SASLib is 24-72x faster than Pandas.

## Test File

Filename      |Rows|Columns|Numeric Columns|String Columns
--------------|----|-------|---------------|--------------
test1.sas7bdat|10  |100    |73             |27

## Python
```
$ python perf_test1.py data_pandas/test1.sas7bdat 100
Minimum: 0.0800 seconds
Median:  0.0868 seconds
Mean:    0.0920 seconds
Maximum: 0.1379 seconds
```

## Julia (ObjectPool String Array)
```
$ julia perf_test1.jl data_pandas/test1.sas7bdat 100
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

Loaded library in 0.664 seconds
BenchmarkTools.Trial: 
  memory estimate:  988.28 KiB
  allocs estimate:  9378
  --------------
  minimum time:     1.149 ms (0.00% GC)
  median time:      1.222 ms (0.00% GC)
  mean time:        1.358 ms (6.98% GC)
  maximum time:     4.425 ms (55.85% GC)
  --------------
  samples:          100
  evals/sample:     1
```

## Julia (Regular String Array)
```
$ julia perf_test_regarray.jl data_pandas/test1.sas7bdat 100
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

Loaded library in 0.680 seconds
BenchmarkTools.Trial:
  memory estimate:  949.63 KiB
  allocs estimate:  8967
  --------------
  minimum time:     1.106 ms (0.00% GC)
  median time:      1.339 ms (0.00% GC)
  mean time:        1.482 ms (6.61% GC)
  maximum time:     4.545 ms (57.52% GC)
  --------------
  samples:          100
  evals/sample:     1
```
