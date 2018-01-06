# Performance Test 3

## Summary

SASLib is ~7x faster than Pandas.

## Test File

Filename             |Rows  |Columns|Numeric Columns|String Columns
---------------------|------|-------|---------------|--------------
productsales.sas7bdat|1440  |10     |4              |6

## Python
```
$ python perf_test1.py data_pandas/productsales.sas7bdat 100
Minimum: 0.0281 seconds
Median:  0.0324 seconds
Mean:    0.0357 seconds
Maximum: 0.1242 seconds
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

Loaded library in 0.630 seconds
BenchmarkTools.Trial: 
  memory estimate:  2.33 MiB
  allocs estimate:  38737
  --------------
  minimum time:     3.984 ms (0.00% GC)
  median time:      4.076 ms (0.00% GC)
  mean time:        4.547 ms (7.03% GC)
  maximum time:     8.595 ms (43.79% GC)
  --------------
  samples:          100
  evals/sample:     1
```

## Julia (regular string array)
```
$ julia perf_test_regarray.jl data_pandas/productsales.sas7bdat 100
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

Loaded library in 0.619 seconds
BenchmarkTools.Trial: 
  memory estimate:  2.31 MiB
  allocs estimate:  38664
  --------------
  minimum time:     3.299 ms (0.00% GC)
  median time:      3.725 ms (0.00% GC)
  mean time:        4.223 ms (9.15% GC)
  maximum time:     9.616 ms (43.66% GC)
  --------------
  samples:          100
  evals/sample:     1
```