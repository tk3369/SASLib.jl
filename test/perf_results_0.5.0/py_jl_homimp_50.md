# Julia/Python Performance Test Result

## Summary

Julia is ~10.5x faster than Python/Pandas

## Test File

Iterations: 50

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
homimp.sas7bdat|1.2 MB|46641|6|1|5

## Python
```
$ python -V
Python 3.6.3 :: Anaconda, Inc.

$ python perf_test1.py data_AHS2013/homimp.sas7bdat 50
Minimum: 0.2726 seconds
Median:  0.2953 seconds
Mean:    0.2944 seconds
Maximum: 0.3236 seconds

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
  memory estimate:  20.56 MiB
  allocs estimate:  513212
  --------------
  minimum time:     45.918 ms (0.00% GC)
  median time:      52.767 ms (10.15% GC)
  mean time:        53.208 ms (9.78% GC)
  maximum time:     60.720 ms (14.54% GC)
  --------------
  samples:          50
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
  memory estimate:  19.38 MiB
  allocs estimate:  512257
  --------------
  minimum time:     25.901 ms (0.00% GC)
  median time:      39.589 ms (34.18% GC)
  mean time:        40.855 ms (34.82% GC)
  maximum time:     121.562 ms (76.55% GC)
  --------------
  samples:          50
  evals/sample:     1
```
