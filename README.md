# SASLib.jl

[![Build Status](https://travis-ci.org/tk3369/SASLib.jl.svg?branch=master)](https://travis-ci.org/tk3369/SASLib.jl)
[![codecov.io](http://codecov.io/github/tk3369/SASLib.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/SASLib.jl?branch=master)

This project started out as a port of Pandas' read_sas function.  Since the first public release, several bugs have been fixed and additional features have been added e.g. reading a subset of columns.  The goal is to have a fast reader that allows greater interoperability of Julia with the SAS ecosystem.

Only `sas7bdat` format is supported, however.  If anyone needs to read `xport` files, please submit an issue.  Pull requests are welcome as well.

## Installation

```
Pkg.add("SASLib")
```

## Read Performance

I did benchmarking mostly on my Macbook Pro laptop.  In general, the Julia implementation is somewhere between 7-25x faster than the Python counterpart.  Test results are documented in the `test/perf_results_<version>` folders.

## User Guide

### Basic Use Case

Use the `readsas` function to read a SAS7BDAT file.  The result is a dictionary of various information about the file as well as the data itself.

```julia
julia> using SASLib

julia> x = readsas("productsales.sas7bdat")
Read productsales.sas7bdat with size 1440 x 10 in 1.05315 seconds
Dict{Symbol,Any} with 17 entries:
  :filename             => "productsales.sas7bdat"
  :page_length          => 8192
  :file_encoding        => "US-ASCII"
  :system_endianness    => :LittleEndian
  :ncols                => 10
  :column_types         => Type[Float64, Float64, String, String, String, String, String, Float64, Float64, Union{Date, Missings.Missing}]
  :column_info          => Tuple{Int64,Symbol,Symbol,Type,DataType}[(1, :ACTUAL, :Number, Float64, Array{Float64,1}), (2, :PREDICT, :Number, Float64, A…
  :data                 => Dict{Any,Any}(Pair{Any,Any}(:QUARTER, [1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0, 4.0  …  1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.…
  :perf_type_conversion => 0.0399293
  :page_count           => 18
  :column_names         => String["ACTUAL", "PREDICT", "COUNTRY", "REGION", "DIVISION", "PRODTYPE", "PRODUCT", "QUARTER", "YEAR", "MONTH"]
  :column_symbols       => Symbol[:ACTUAL, :PREDICT, :COUNTRY, :REGION, :DIVISION, :PRODTYPE, :PRODUCT, :QUARTER, :YEAR, :MONTH]
  :column_lengths       => [8, 8, 10, 10, 10, 10, 10, 8, 8, 8]
  :file_endianness      => :LittleEndian
  :nrows                => 1440
  :perf_read_data       => 0.035717
  :column_offsets       => [0, 8, 40, 50, 60, 70, 80, 16, 24, 32]
```

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
   ⋮  

```

Additional metadata are available as follows:

Key              |Type           |Description
-----------------|---------------|-------------------------------
:nrows           | Int           | Number of rows in the result
:ncols           | Int           | Number of columns in the result
:filename        | String        | Filename for which data was read
:file_encoding   | String        | Character encoding used in the file
:file_endianness | Symbol        | Either :LittleEndian or :BigEndian
:column_symbols  | Array{Symbol} | Column symbols
:column_names    | Array{String} | Column names
:column_types    | Array{Type}   | Column types e.g. Float64, String
:column_info     | Array{Tuple}  | Tuple (column#, symbol, Num/Str, eltype, array type)
:column_lengths  | Array{Int}    | Column lengths as in the SAS file format
:column_offsets  | Array{Int}    | Column offsets as in the SAS file format
:page_length     | Int           | Page length as in the SAS file format
:page_count      | Int           | Number of pages as in the SAS file format
:perf\_read\_data  | Float       | Performance stat: seconds used to read data into memory
:perf\_type\_conversion  | Float | Performance stat: seconds used to convert data to proper types e.g. Date/DateTime
:system_endianness | Symbol      | Either :LittleEndian or :BigEndian 

### Conversion to DataFrame

Since the data is just a Dict of array columns, it's easy to convert into a DataFrame:

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

You may find the columns being mixed up a bit annoying since a regular Dict does not have any concept of orders and DataFrame just sort them aphabetically.  To work around that issue, you can leverage `:column_symbols` array, which has the _natural order_ from the file:

```
julia> df = DataFrame(((c => x[:data][c]) for c in x[:column_symbols])...);

julia> head(df,5)
5×10 DataFrames.DataFrame
│ Row │ ACTUAL │ PREDICT │ COUNTRY │ REGION │ DIVISION  │ PRODTYPE  │ PRODUCT │ QUARTER │ YEAR   │ MONTH      │
├─────┼────────┼─────────┼─────────┼────────┼───────────┼───────────┼─────────┼─────────┼────────┼────────────┤
│ 1   │ 925.0  │ 850.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 1.0     │ 1993.0 │ 1993-01-01 │
│ 2   │ 999.0  │ 297.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 1.0     │ 1993.0 │ 1993-02-01 │
│ 3   │ 608.0  │ 846.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 1.0     │ 1993.0 │ 1993-03-01 │
│ 4   │ 642.0  │ 533.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 2.0     │ 1993.0 │ 1993-04-01 │
│ 5   │ 656.0  │ 646.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 2.0     │ 1993.0 │ 1993-05-01 │
```

### Inclusion/Exclusion of Columns

It is always faster to read only the columns that you need.  The `include_columns` argument comes in handy:

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

### Incremental Reading

If you need to read files incrementally, you can do so as such:

```julia
handler = SASLib.open("productsales.sas7bdat")
results = SASLib.read(handler, 3)   # read 3 rows
results = SASLib.read(handler, 4)   # read next 4 rows
SASLib.close(handler)              # remember to close the handler when done
```

Note that there is no facility at the moment to jump and read a subset of rows.  Currently, SASLib always read from the beginning.

### String Columns

By default, string columns are read into a special AbstractArray structure called ObjectPool in order to conserve memory space that might otherwise be wasted for duplicate string values.  SASLib tries to be smart -- when it encounters too many unique values (> 10%) in a large array (> 2000 rows), it falls back to a regular Julia array.

You can use a different array type (e.g. [CategoricalArray](https://github.com/JuliaData/CategoricalArrays.jl) or [PooledArray](https://github.com/JuliaComputing/PooledArrays.jl)) for any columns as you wish by specifying a `string_array_fn` parameter when reading the file.  This argument must be a Dict that maps a column symbol into a function that takes an integer argument and returns any array of that size.

Here's the normal case:

```
julia> x = readsas("productsales.sas7bdat", include_columns=[:COUNTRY, :REGION]);
Read productsales.sas7bdat with size 1440 x 2 in 0.00277 seconds

julia> typeof.(collect(values(x[:data])))
2-element Array{DataType,1}:
 SASLib.ObjectPool{String,UInt16}
 SASLib.ObjectPool{String,UInt16}
```

Now, you can force SASLib to use a regular array as such.

```
julia> x = readsas("productsales.sas7bdat", include_columns=[:COUNTRY, :REGION],
                   string_array_fn=Dict(:COUNTRY => (n)->fill("",n)));
Read productsales.sas7bdat with size 1440 x 2 in 0.05009 seconds

julia> typeof.(collect(values(x[:data])))
2-element Array{DataType,1}:
 Array{String,1}                 
 SASLib.ObjectPool{String,UInt16}
```

For convenience, `SASLib.REGULAR_STR_ARRAY` could be used instead.  In addition, if you need all columns to be configured then the key of the `string_array_fn` dict may be just the symbol `:_all_`. 

```
julia> x = readsas("productsales.sas7bdat", include_columns=[:COUNTRY, :REGION],
                   string_array_fn=Dict(:_all_ => REGULAR_STR_ARRAY));
Read productsales.sas7bdat with size 1440 x 2 in 0.01005 seconds

julia> typeof.(collect(values(x[:data])))
2-element Array{DataType,1}:
 Array{String,1}
 Array{String,1}
```

## Why another package?

At first, I was just going to use [ReadStat.jl](https://github.com/davidanthoff/ReadStat.jl), which uses the [ReadStat C-library](https://github.com/WizardMac/ReadStat).  However, ReadStat does not support reading RDC-compressed binary files.  I could have chosen to contribute to that project but I would rather learn and code in Julia instead ;-)  The implementation in Pandas is fairly straightforward, making it a relatively easy porting project.  

## Porting Notes

I chose to copy the code from Pandas and made minimal changes so I can have a working version quickly.  Hence, the code isn't very Julia-friendly e.g. variable and function naming are all mixed up.  It is not a priority at this point but I would think some major refactoring would be required to clean up the code.

## Credits

- Jared Hobbs, the author of the SAS reader code from Python Pandas.  See LICENSE_SAS7BDAT.md.
- [Evan Miller](https://github.com/evanmiller), the author of ReadStat C/C++ library.  See LICENSE_READSTAT.md.
- [David Anthoff](https://github.com/davidanthoff), who provide many valuable ideas at the early stage of development.

I also want to thank all the active members at the [Julia Discourse community] (https://discourse.julialang.org).  This project wouldn't be possible without all the help I got from the community.  That's the beauty of open-source development.
