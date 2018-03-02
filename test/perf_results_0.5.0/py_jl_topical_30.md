# Julia/Python Performance Test Result

## Summary

Julia is ~10.7x faster than Python/Pandas

## Test File

Iterations: 30

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
topical.sas7bdat|13.6 MB|84355|114|8|106

## Python
```
$ python -V
Python 3.6.3 :: Anaconda, Inc.

$ python perf_test1.py data_AHS2013/topical.sas7bdat 30
Minimum: 18.1673 seconds
Median:  20.0589 seconds
Mean:    20.0653 seconds
Maximum: 23.6490 seconds

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
  memory estimate:  632.36 MiB
  allocs estimate:  18653372
  --------------
  minimum time:     2.183 s (9.05% GC)
  median time:      2.306 s (10.79% GC)
  mean time:        2.282 s (10.57% GC)
  maximum time:     2.357 s (11.76% GC)
  --------------
  samples:          3
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
  memory estimate:  596.44 MiB
  allocs estimate:  18612061
  --------------
  minimum time:     1.699 s (0.00% GC)
  median time:      2.076 s (48.51% GC)
  mean time:        2.071 s (37.46% GC)
  maximum time:     2.440 s (54.15% GC)
  --------------
  samples:          3
  evals/sample:     1
```
