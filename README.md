# SASLib.jl

[![Build Status](https://travis-ci.org/tk3369/SASLib.jl.svg)](https://travis-ci.org/tk3369/SASLib.jl)
[![codecov.io](http://codecov.io/github/tk3369/SASLib.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/SASLib.jl?branch=master)

This is a port of Pandas' read_sas function.  

Only `sas7bdat` format is supported, however.  If anyone needs to read `xport` formatted files, please create an issue or contribute/send me a pull request.

## Installation

```
Pkg.add("SASLib")
```

## Examples

Use the `readsas` function to read the file.  The result is a dictionary of various information about the file as well as the data itself.

```julia
julia> using SASLib

julia> x = readsas("productsales.sas7bdat")
Read data set of size 1440 x 10 in 2.0 seconds
Dict{Symbol,Any} with 16 entries:
  :filename             => "productsales.sas7bdat"
  :page_length          => 8192
  :file_encoding        => "US-ASCII"
  :system_endianness    => :LittleEndian
  :ncols                => 10
  :column_types         => Type[Float64, Float64, Union{AbstractString, Missings.Missing}, Union{AbstractString, Missings.Missing}, Union{AbstractString,…
  :data                 => Dict{Any,Any}(Pair{Any,Any}(:QUARTER, [1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0, 4.0  …  1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0,…
  :perf_type_conversion => 0.0262305
  :page_count           => 18
  :column_names         => String["QUARTER", "YEAR", "COUNTRY", "DIVISION", "REGION", "MONTH", "PREDICT", "ACTUAL", "PRODTYPE", "PRODUCT"]
  :column_symbols       => Symbol[:QUARTER, :YEAR, :COUNTRY, :DIVISION, :REGION, :MONTH, :PREDICT, :ACTUAL, :PRODTYPE, :PRODUCT]
  :column_lengths       => [8, 8, 10, 10, 10, 10, 10, 8, 8, 8]
  :file_endianness      => :LittleEndian
  :nrows                => 1440
  :perf_read_data       => 0.00639309
  :column_offsets       => [0, 8, 40, 50, 60, 70, 80, 16, 24, 32]
```

Number of columns and rows are returned as in `:ncols` and `:nrows` respectively.

The data, reference by `:data` key, is represented as a Dict object with the column symbol as the key.

```juia
julia> x[:data][:ACTUAL]
1440-element Array{Float64,1}:
 925.0
 999.0
 608.0
 642.0
 656.0
 948.0
 612.0
 114.0
 685.0
 657.0
 608.0
 353.0
 107.0
   ⋮  
```

If you really like DataFrame, you can easily convert as such:

```julia
julia> using DataFrames

julia> df = DataFrame(x[:data]);

julia> head(df, 5)
5×10 DataFrames.DataFrame
│ Row │ ACTUAL │ COUNTRY │ DIVISION  │ MONTH      │ PREDICT │ PRODTYPE  │ PRODUCT │ QUARTER │ REGION │ YEAR   │
├─────┼────────┼─────────┼───────────┼────────────┼─────────┼───────────┼─────────┼─────────┼────────┼────────┤
│ 1   │ 925.0  │ CANADA  │ EDUCATION │ 1993-01-01 │ 850.0   │ FURNITURE │ SOFA    │ 1.0     │ EAST   │ 1993.0 │
│ 2   │ 999.0  │ CANADA  │ EDUCATION │ 1993-02-01 │ 297.0   │ FURNITURE │ SOFA    │ 1.0     │ EAST   │ 1993.0 │
│ 3   │ 608.0  │ CANADA  │ EDUCATION │ 1993-03-01 │ 846.0   │ FURNITURE │ SOFA    │ 1.0     │ EAST   │ 1993.0 │
│ 4   │ 642.0  │ CANADA  │ EDUCATION │ 1993-04-01 │ 533.0   │ FURNITURE │ SOFA    │ 2.0     │ EAST   │ 1993.0 │
│ 5   │ 656.0  │ CANADA  │ EDUCATION │ 1993-05-01 │ 646.0   │ FURNITURE │ SOFA    │ 2.0     │ EAST   │ 1993.0 │
```

If you only need to read few columns, just pass an `include_columns` argument:

```
julia> head(DataFrame(readsas("productsales.sas7bdat", include_columns=[:YEAR, :MONTH, :PRODUCT, :ACTUAL])[:data]))
Read data set of size 1440 x 4 in 0.004 seconds
6×4 DataFrames.DataFrame
│ Row │ ACTUAL │ MONTH      │ PRODUCT │ YEAR   │
├─────┼────────┼────────────┼─────────┼────────┤
│ 1   │ 925.0  │ 1993-01-01 │ SOFA    │ 1993.0 │
│ 2   │ 999.0  │ 1993-02-01 │ SOFA    │ 1993.0 │
│ 3   │ 608.0  │ 1993-03-01 │ SOFA    │ 1993.0 │
│ 4   │ 642.0  │ 1993-04-01 │ SOFA    │ 1993.0 │
│ 5   │ 656.0  │ 1993-05-01 │ SOFA    │ 1993.0 │
│ 6   │ 948.0  │ 1993-06-01 │ SOFA    │ 1993.0 │
```

Likewise, you can read all columns except the ones you don't want as specified in `exclude_columns` argument:

```
julia> head(DataFrame(readsas("productsales.sas7bdat", exclude_columns=[:YEAR, :MONTH, :PRODUCT, :ACTUAL])[:data]))
Read data set of size 1440 x 6 in 0.031 seconds
6×6 DataFrames.DataFrame
│ Row │ COUNTRY │ DIVISION  │ PREDICT │ PRODTYPE  │ QUARTER │ REGION │
├─────┼─────────┼───────────┼─────────┼───────────┼─────────┼────────┤
│ 1   │ CANADA  │ EDUCATION │ 850.0   │ FURNITURE │ 1.0     │ EAST   │
│ 2   │ CANADA  │ EDUCATION │ 297.0   │ FURNITURE │ 1.0     │ EAST   │
│ 3   │ CANADA  │ EDUCATION │ 846.0   │ FURNITURE │ 1.0     │ EAST   │
│ 4   │ CANADA  │ EDUCATION │ 533.0   │ FURNITURE │ 2.0     │ EAST   │
│ 5   │ CANADA  │ EDUCATION │ 646.0   │ FURNITURE │ 2.0     │ EAST   │
│ 6   │ CANADA  │ EDUCATION │ 486.0   │ FURNITURE │ 2.0     │ EAST   │
```

If you need to read files incrementally:

```julia
handler = SASLib.open("productsales.sas7bdat")
results = SASLib.read(handler, 3)   # read 3 rows
results = SASLib.read(handler, 4)   # read next 4 rows
SASLib.close(handler)              # remember to close the handler when done
```

## Read Performance

I don't have too much performance test results but initial comparison between SASLib.jl and Pandas on my Macbook Pro is encouraging.  In general, the Julia implementation is somewhere between 4x to 7x faster than the Python counterpart. See the perf\_results\_* folders for test results related to the version being published.

## Why another package?

At first, I was just going to use ReadStat.  However, ReadStat does not support reading files with compressed binary data.  I could have chosen to contribute to that project instead but I would rather learn and code in Julia  ;-)  The implementation in Pandas is fairly straightforward, making it a relatively easy porting project.  

## Porting Notes

I chose to copy the code from Pandas and made minimal changes so I can have a working version quickly.  Hence, the code isn't very Julia-friendly e.g. variable and function naming are all mixed up.  It is not a priority at this point but I would think some major refactoring would be required to make it more clean & performant.

## Credits

Many thanks to Jared Hobbs, the original author of the SAS I/O code from Python Pandas.  See LICENSE_SAS7BDAT.md for license details.
