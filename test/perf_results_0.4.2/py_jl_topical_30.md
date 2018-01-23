# Julia/Python Performance Test Result

## Summary

Julia is ~16.1x faster than Python/Pandas

## Test File

Iterations: 30

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
topical.sas7bdat|13.6 MB|84355|114|8|106

## Python
```
$ python -V
Python 3.6.3 :: Anaconda custom (64-bit)

$ python perf_test1.py data_AHS2013/topical.sas7bdat 30
Minimum: 18.1696 seconds
Median:  19.7381 seconds
Mean:    20.0185 seconds
Maximum: 23.0960 seconds

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
  memory estimate:  632.37 MiB
  allocs estimate:  18653672
  --------------
  minimum time:     2.296 s (9.82% GC)
  median time:      2.422 s (11.51% GC)
  mean time:        2.388 s (11.26% GC)
  maximum time:     2.445 s (11.40% GC)
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
  memory estimate:  596.26 MiB
  allocs estimate:  18608580
  --------------
  minimum time:     1.129 s (0.00% GC)
  median time:      2.220 s (47.16% GC)
  mean time:        1.953 s (41.51% GC)
  maximum time:     2.511 s (55.19% GC)
  --------------
  samples:          3
  evals/sample:     1
```
