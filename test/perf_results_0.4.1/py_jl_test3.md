# Performance Test 3

## Summary

SASLib is ~14-22x faster than Pandas.

## Test File

Filename             |Rows  |Columns|Numeric Columns|String Columns
---------------------|------|-------|---------------|--------------
productsales.sas7bdat|1440  |10     |4              |6

## Python
```
$ python -V
Python 3.6.3 :: Anaconda custom (64-bit)
$ python perf_test1.py data_pandas/productsales.sas7bdat 100
Minimum: 0.0286 seconds
Median:  0.0316 seconds
Mean:    0.0329 seconds
Maximum: 0.0894 seconds
```

## Julia (ObjectPool string array)
```
$ julia perf_test1.jl data_pandas/productsales.sas7bdat 100
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

Loaded library in 4.693 seconds
BenchmarkTools.Trial:
  memory estimate:  1.07 MiB
  allocs estimate:  18573
  --------------
  minimum time:     2.088 ms (0.00% GC)
  median time:      2.133 ms (0.00% GC)
  mean time:        2.320 ms (4.10% GC)
  maximum time:     5.123 ms (47.12% GC)
  --------------
  samples:          100
  evals/sample:     1
```

## Julia (regular string array)
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

Loaded library in 0.651 seconds
BenchmarkTools.Trial:
  memory estimate:  1.05 MiB
  allocs estimate:  18500
  --------------
  minimum time:     1.337 ms (0.00% GC)
  median time:      1.385 ms (0.00% GC)
  mean time:        1.556 ms (8.02% GC)
  maximum time:     5.486 ms (69.40% GC)
  --------------
  samples:          100
  evals/sample:     1

```
