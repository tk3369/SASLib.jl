# Julia/Python Performance Test Result

## Summary

Julia is ~96.3x faster than Python/Pandas

## Test File

Iterations: 100

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
test1.sas7bdat|131.1 kB|10|100|75|25

## Python
```
$ python -V
Python 3.6.3 :: Anaconda, Inc.

$ python perf_test1.py data_pandas/test1.sas7bdat 100
Minimum: 0.0827 seconds
Median:  0.0869 seconds
Mean:    0.0882 seconds
Maximum: 0.1081 seconds

```

## Julia (ObjectPool)
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

BenchmarkTools.Trial: 
  memory estimate:  920.72 KiB
  allocs estimate:  7946
  --------------
  minimum time:     858.533 μs (0.00% GC)
  median time:      914.394 μs (0.00% GC)
  mean time:        1.063 ms (8.94% GC)
  maximum time:     3.900 ms (60.65% GC)
  --------------
  samples:          100
  evals/sample:     1
```

## Julia (Regular String Array)
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

BenchmarkTools.Trial: 
  memory estimate:  1.04 MiB
  allocs estimate:  10880
  --------------
  minimum time:     1.569 ms (0.00% GC)
  median time:      1.714 ms (0.00% GC)
  mean time:        1.941 ms (5.08% GC)
  maximum time:     4.866 ms (54.98% GC)
  --------------
  samples:          100
  evals/sample:     1
```
