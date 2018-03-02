# Julia/Python Performance Test Result

## Summary

Julia is ~20.7x faster than Python/Pandas

## Test File

Iterations: 100

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
productsales.sas7bdat|148.5 kB|1440|10|5|5

## Python
```
$ python -V
Python 3.6.3 :: Anaconda, Inc.

$ python perf_test1.py data_pandas/productsales.sas7bdat 100
Minimum: 0.0280 seconds
Median:  0.0318 seconds
Mean:    0.0328 seconds
Maximum: 0.0491 seconds

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
  memory estimate:  1.07 MiB
  allocs estimate:  18468
  --------------
  minimum time:     2.022 ms (0.00% GC)
  median time:      2.213 ms (0.00% GC)
  mean time:        2.383 ms (4.38% GC)
  maximum time:     5.835 ms (51.17% GC)
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
  memory estimate:  1.06 MiB
  allocs estimate:  18646
  --------------
  minimum time:     1.352 ms (0.00% GC)
  median time:      1.441 ms (0.00% GC)
  mean time:        1.896 ms (7.26% GC)
  maximum time:     7.269 ms (0.00% GC)
  --------------
  samples:          100
  evals/sample:     1
```
