# Julia/Python Performance Test Result

## Summary

Julia is ~27.3x faster than Python/Pandas

## Test File

Iterations: 30

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
topical.sas7bdat|13.6 MB|84355|114|8|106

## Python
```
$ python -V
Python 3.7.1
$ python perf_test1.py data_AHS2013/topical.sas7bdat 30
Minimum: 46.9720 seconds
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
  memory estimate:  685.66 MiB
  allocs estimate:  19193161
  --------------
  minimum time:     1.720 s (6.37% GC)
  median time:      1.806 s (11.83% GC)
  mean time:        1.796 s (10.69% GC)
  maximum time:     1.863 s (13.57% GC)
  --------------
  samples:          3
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
  memory estimate:  648.04 MiB
  allocs estimate:  19048983
  --------------
  minimum time:     1.994 s (46.01% GC)
  median time:      2.559 s (51.16% GC)
  mean time:        2.559 s (51.16% GC)
  maximum time:     3.123 s (54.45% GC)
  --------------
  samples:          2
  evals/sample:     1
```
