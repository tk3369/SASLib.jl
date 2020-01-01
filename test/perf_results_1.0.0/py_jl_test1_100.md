# Julia/Python Performance Test Result

## Summary

Julia is ~118.8x faster than Python/Pandas

## Test File

Iterations: 100

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
test1.sas7bdat|131.1 kB|10|100|73|27

## Python
```
$ python -V
Python 3.7.1
$ python perf_test1.py data_pandas/test1.sas7bdat 100
Minimum: 0.1036 seconds
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
  memory estimate:  1.00 MiB
  allocs estimate:  7132
  --------------
  minimum time:     871.807 μs (0.00% GC)
  median time:      1.254 ms (0.00% GC)
  mean time:        1.470 ms (6.75% GC)
  maximum time:     6.470 ms (78.01% GC)
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
  memory estimate:  990.86 KiB
  allocs estimate:  6819
  --------------
  minimum time:     1.119 ms (0.00% GC)
  median time:      2.666 ms (0.00% GC)
  mean time:        9.009 ms (6.71% GC)
  maximum time:     161.985 ms (0.00% GC)
  --------------
  samples:          100
  evals/sample:     1
```
