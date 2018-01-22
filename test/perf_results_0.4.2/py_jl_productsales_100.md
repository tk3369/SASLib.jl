# Julia/Python Performance Test Result

## Summary

Julia is ~21.1x faster than Python/Pandas

## Test File

Iterations: 100

Filename|Size|Rows|Columns|Numeric Columns|String Columns
--------|----|----|-------|---------------|--------------
productsales.sas7bdat|148.5 kB|1440|10|5|5

## Python
```
$ python -V
Python 3.6.3 :: Anaconda custom (64-bit)

$ python perf_test1.py data_pandas/productsales.sas7bdat 100
Minimum: 0.0292 seconds
Median:  0.0316 seconds
Mean:    0.0325 seconds
Maximum: 0.0572 seconds

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
  allocs estimate:  18583
  --------------
  minimum time:     2.084 ms (0.00% GC)
  median time:      2.188 ms (0.00% GC)
  mean time:        2.408 ms (3.88% GC)
  maximum time:     5.143 ms (47.78% GC)
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
  memory estimate:  1.05 MiB
  allocs estimate:  18510
  --------------
  minimum time:     1.382 ms (0.00% GC)
  median time:      1.430 ms (0.00% GC)
  mean time:        1.608 ms (7.05% GC)
  maximum time:     5.258 ms (65.43% GC)
  --------------
  samples:          100
  evals/sample:     1
```
