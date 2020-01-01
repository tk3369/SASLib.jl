# Julia/Python Performance Test Result

## Summary

Julia is ~27.9x faster than Python/Pandas

## Test File

Iterations: 50

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
homimp.sas7bdat|1.2 MB|46641|6|1|5

## Python
```
$ python -V
Python 3.7.1
$ python perf_test1.py data_AHS2013/homimp.sas7bdat 50
Minimum: 0.5793 seconds
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
  memory estimate:  20.20 MiB
  allocs estimate:  494963
  --------------
  minimum time:     39.500 ms (0.00% GC)
  median time:      44.556 ms (0.00% GC)
  mean time:        44.054 ms (4.70% GC)
  maximum time:     63.587 ms (7.46% GC)
  --------------
  samples:          50
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
  memory estimate:  18.02 MiB
  allocs estimate:  428420
  --------------
  minimum time:     20.776 ms (0.00% GC)
  median time:      25.170 ms (0.00% GC)
  mean time:        29.005 ms (18.45% GC)
  maximum time:     109.289 ms (73.77% GC)
  --------------
  samples:          50
  evals/sample:     1
```
