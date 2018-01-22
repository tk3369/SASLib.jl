# Julia/Python Performance Test Result

## Summary

Julia is ~72.8x faster than Python/Pandas

## Test File

Iterations: 100

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
test1.sas7bdat|131.1 kB|10|100|75|25

## Python
```
$ python -V
Python 3.6.3 :: Anaconda custom (64-bit)

$ python perf_test1.py data_pandas/test1.sas7bdat 100
Minimum: 0.0806 seconds
Median:  0.0861 seconds
Mean:    0.0872 seconds
Maximum: 0.1226 seconds

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
  memory estimate:  989.53 KiB
  allocs estimate:  9388
  --------------
  minimum time:     1.147 ms (0.00% GC)
  median time:      1.233 ms (0.00% GC)
  mean time:        1.439 ms (6.35% GC)
  maximum time:     4.053 ms (56.94% GC)
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
  memory estimate:  950.88 KiB
  allocs estimate:  8977
  --------------
  minimum time:     1.107 ms (0.00% GC)
  median time:      1.194 ms (0.00% GC)
  mean time:        1.379 ms (7.08% GC)
  maximum time:     4.468 ms (61.84% GC)
  --------------
  samples:          100
  evals/sample:     1
```
