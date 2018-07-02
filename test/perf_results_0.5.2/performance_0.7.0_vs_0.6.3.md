# Performance Comparison (0.7.0-beta vs 0.6.3)

## Small Data Set

Reading data_pandas/productsales.sas7bdat (140K) is 12% faster in v0.7.

v0.7
```
julia> @benchmark readsas("data_pandas/productsales.sas7bdat", verbose_level = 0) 
BenchmarkTools.Trial: 
  memory estimate:  1.01 MiB
  allocs estimate:  14727
  --------------
  minimum time:     1.748 ms (0.00% GC)
  median time:      1.843 ms (0.00% GC)
  mean time:        2.027 ms (5.61% GC)
  maximum time:     58.967 ms (96.56% GC)
  --------------
  samples:          2458
  evals/sample:     1
```

v0.6.3
```
julia> @benchmark readsas("data_pandas/productsales.sas7bdat", verbose_level = 0)
BenchmarkTools.Trial: 
  memory estimate:  1.07 MiB
  allocs estimate:  18505
  --------------
  minimum time:     1.987 ms (0.00% GC)
  median time:      2.150 ms (0.00% GC)
  mean time:        2.367 ms (5.56% GC)
  maximum time:     10.130 ms (70.77% GC)
  --------------
  samples:          2108
  evals/sample:     1
```

## Larger Data Set

Reading data_AHS2013/topical.sas7bdat (14 MB) is 18% faster in v0.7.

v0.7
```
julia> @benchmark readsas("data_AHS2013/topical.sas7bdat", verbose_level = 0) seconds=60
BenchmarkTools.Trial: 
  memory estimate:  649.63 MiB
  allocs estimate:  19011924
  --------------
  minimum time:     1.959 s (10.46% GC)
  median time:      2.042 s (12.78% GC)
  mean time:        2.061 s (12.59% GC)
  maximum time:     2.348 s (12.17% GC)
  --------------
  samples:          30
  evals/sample:     1
```

v0.6.3
```
julia> @benchmark readsas("data_AHS2013/topical.sas7bdat", verbose_level = 0) seconds=60
BenchmarkTools.Trial: 
  memory estimate:  632.36 MiB
  allocs estimate:  18653427
  --------------
  minimum time:     2.391 s (10.82% GC)
  median time:      2.520 s (13.07% GC)
  mean time:        2.524 s (12.84% GC)
  maximum time:     2.638 s (12.87% GC)
  --------------
  samples:          24
  evals/sample:     1
```