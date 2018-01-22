# Julia/Python Performance Test Result

## Summary

Julia is ~10.7x faster than Python/Pandas

## Test File

Iterations: 50

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
homimp.sas7bdat|1.2 MB|46641|6|1|5

## Python
```
$ python -V
Python 3.6.3 :: Anaconda custom (64-bit)

$ python perf_test1.py data_AHS2013/homimp.sas7bdat 50
Minimum: 0.2720 seconds
Median:  0.3014 seconds
Mean:    0.3140 seconds
Maximum: 0.4728 seconds

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
  allocs estimate:  513299
  --------------
  minimum time:     47.109 ms (0.00% GC)
  median time:      56.312 ms (11.21% GC)
  mean time:        57.920 ms (10.72% GC)
  maximum time:     78.471 ms (9.23% GC)
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
  memory estimate:  19.37 MiB
  allocs estimate:  512178
  --------------
  minimum time:     25.528 ms (0.00% GC)
  median time:      39.970 ms (33.88% GC)
  mean time:        41.932 ms (35.10% GC)
  maximum time:     113.933 ms (76.81% GC)
  --------------
  samples:          50
  evals/sample:     1
```
