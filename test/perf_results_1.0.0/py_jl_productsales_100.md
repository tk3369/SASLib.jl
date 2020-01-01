# Julia/Python Performance Test Result

## Summary

Julia is ~46.9x faster than Python/Pandas

## Test File

Iterations: 100

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
productsales.sas7bdat|148.5 kB|1440|10|4|6

## Python
```
$ python -V
Python 3.7.1
$ python perf_test1.py data_pandas/productsales.sas7bdat 100
Minimum: 0.0505 seconds
```

## Julia (ObjectPool)
```
Julia Version 1.3.0
Commit 46ce4d7933 (2019-11-26 06:09 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin19.0.0)
  CPU: Intel(R) Core(TM) i5-4258U CPU @ 2.40GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-6.0.1 (ORCJIT, haswell)
Environment:
  JULIA_NUM_THREADS = 4

BenchmarkTools.Trial: 
  memory estimate:  1.17 MiB
  allocs estimate:  14693
  --------------
  minimum time:     1.745 ms (0.00% GC)
  median time:      2.431 ms (0.00% GC)
  mean time:        2.679 ms (2.39% GC)
  maximum time:     5.482 ms (60.67% GC)
  --------------
  samples:          100
  evals/sample:     1
```

## Julia (Regular String Array)
```
Julia Version 1.3.0
Commit 46ce4d7933 (2019-11-26 06:09 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin19.0.0)
  CPU: Intel(R) Core(TM) i5-4258U CPU @ 2.40GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-6.0.1 (ORCJIT, haswell)
Environment:
  JULIA_NUM_THREADS = 4

BenchmarkTools.Trial: 
  memory estimate:  1.15 MiB
  allocs estimate:  14638
  --------------
  minimum time:     1.078 ms (0.00% GC)
  median time:      3.277 ms (0.00% GC)
  mean time:        6.618 ms (3.48% GC)
  maximum time:     83.970 ms (0.00% GC)
  --------------
  samples:          100
  evals/sample:     1
```
