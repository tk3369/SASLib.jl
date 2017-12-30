# Read performance when reading only half of the data

## Results

Read time is reduced by 40% when reading half of the data.

## Test Scenario

This test file has just 2 numeric columns.  We would like to know the performance
of reading only 1 column from this file.

Filename|Rows|Columns|Numeric Columns|String Columns
--------|----|-------|---------------|--------------
numeric_1000000_2.sas7bdat|1,000,000|2|2|0

## Test Log

```
julia> @benchmark readsas("numeric_1000000_2.sas7bdat", verbose_level=0)
BenchmarkTools.Trial:
  memory estimate:  399.04 MiB
  allocs estimate:  3031083
  --------------
  minimum time:     358.695 ms (9.31% GC)
  median time:      442.709 ms (25.96% GC)
  mean time:        427.870 ms (20.97% GC)
  maximum time:     482.786 ms (25.29% GC)
  --------------
  samples:          12
  evals/sample:     1

julia> @benchmark readsas("numeric_1000000_2.sas7bdat", include_columns=[:f], verbose_level=0)
BenchmarkTools.Trial:
  memory estimate:  261.71 MiB
  allocs estimate:  2031028
  --------------
  minimum time:     222.832 ms (9.67% GC)
  median time:      235.396 ms (9.70% GC)
  mean time:        261.782 ms (20.75% GC)
  maximum time:     327.359 ms (33.53% GC)
  --------------
  samples:          20
  evals/sample:     1

julia> 262/428
0.6121495327102804
```
