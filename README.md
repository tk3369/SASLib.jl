# SASLib.jl

[![Build Status](https://travis-ci.org/tk3369/SASLib.jl.svg?branch=master)](https://travis-ci.org/tk3369/SASLib.jl)
[![codecov.io](http://codecov.io/github/tk3369/SASLib.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/SASLib.jl?branch=master)

The goal is to have a fast reader that allows greater interoperability of Julia with the SAS ecosystem.  Only `sas7bdat` format is supported.  SASLib is licensed under the MIT Expat license.

_Notes:_ SASLib v0.5.0 coontains a major breaking change in the results being returned from the `readsas` or `SASLib.read` functions.  Please read documentation below about how to use the new `SASLib.ResultSet` object.

## Installation

```
Pkg.add("SASLib")
```

## Read Performance

I did benchmarking mostly on my Macbook Pro laptop.  In general, the Julia implementation is somewhere between 10-100x faster than the Python Pandas.  Test results are documented in the `test/perf_results_<version>` folders.

## User Guide

```
julia> using SASLib
```

### Reading SAS Files

Use the `readsas` function to read a SAS7BDAT file.  

```julia
julia> rs = readsas("productsales.sas7bdat")
Read productsales.sas7bdat with size 1440 x 10 in 0.00256 seconds
SASLib.ResultSet (1440 rows x 10 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:COUNTRY, 4:REGION, 5:DIVISION, 6:PRODTYPE, 7:PRODUCT, 8:QUARTER, 9:YEAR, 10:MONTH
1: 925.0, 850.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-01-01
2: 999.0, 297.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-02-01
3: 608.0, 846.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-03-01
4: 642.0, 533.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 2.0, 1993.0, 1993-04-01
5: 656.0, 646.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 2.0, 1993.0, 1993-05-01
⋮
```

### Accessing Results

There are several ways to access the data conveniently without using any third party packages. Each cell value may be retrieved directly via the regular `[i,j]` index.  Accessing an entire row or column returns a tuple and a vector respectively.

```
julia> rs[4,2]
533.0

julia> rs[4, :PREDICT]
533.0

julia> rs[1]
(925.0, 850.0, "CANADA", "EAST", "EDUCATION", "FURNITURE", "SOFA", 1.0, 1993.0, 1993-01-01)

julia> rs[:ACTUAL]
1440-element Array{Float64,1}:
 925.0
 999.0
 608.0
 ⋮
```

You may access a portion of the result set by indexing with unit range and column symbols. 

```
julia> rs[2:4]
SASLib.ResultSet (3 rows x 10 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:COUNTRY, 4:REGION, 5:DIVISION, 6:PRODTYPE, 7:PRODUCT, 8:QUARTER, 9:YEAR, 10:MONTH
1: 999.0, 297.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-02-01
2: 608.0, 846.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-03-01
3: 642.0, 533.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 2.0, 1993.0, 1993-04-01


julia> rs[:ACTUAL, :PREDICT, :YEAR, :MONTH]
SASLib.ResultSet (1440 rows x 4 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:YEAR, 4:MONTH
1: 925.0, 850.0, 1993.0, 1993-01-01
2: 999.0, 297.0, 1993.0, 1993-02-01
3: 608.0, 846.0, 1993.0, 1993-03-01
4: 642.0, 533.0, 1993.0, 1993-04-01
5: 656.0, 646.0, 1993.0, 1993-05-01
⋮
```

### Assignments

You may assign values at the cell level.  Doing so has a side effect.

```
julia> srs = rs[:ACTUAL, :PREDICT, :YEAR, :MONTH][1:2]
SASLib.ResultSet (2 rows x 4 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:YEAR, 4:MONTH
1: 925.0, 850.0, 1993.0, 1993-01-01
2: 999.0, 297.0, 1993.0, 1993-02-01

julia> srs[2,2] = 3
3

julia> rs[1:2]
SASLib.ResultSet (2 rows x 10 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:COUNTRY, 4:REGION, 5:DIVISION, 6:PRODTYPE, 7:PRODUCT, 8:QUARTER, 9:YEAR, 10:MONTH
1: 925.0, 850.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-01-01
2: 999.0, 3.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-02-01
```

### Iteration

ResultSet implements the usual Base.iteration interface, so it's easy to walk through the results:

```
julia> for r in rs
         r[1] < 10 && println(r)
       end
(5.0, 425.0, "CANADA", "EAST", "CONSUMER", "FURNITURE", "SOFA", 1.0, 1993.0, 1993-01-01)
(8.0, 957.0, "CANADA", "EAST", "CONSUMER", "FURNITURE", "SOFA", 3.0, 1993.0, 1993-07-01)
(6.0, 214.0, "CANADA", "WEST", "EDUCATION", "OFFICE", "TABLE", 3.0, 1993.0, 1993-08-01)
(9.0, 814.0, "CANADA", "WEST", "EDUCATION", "OFFICE", "TABLE", 4.0, 1993.0, 1993-11-01)
(3.0, 405.0, "CANADA", "WEST", "CONSUMER", "FURNITURE", "SOFA", 2.0, 1994.0, 1994-05-01)
(3.0, 938.0, "GERMANY", "WEST", "EDUCATION", "FURNITURE", "BED", 1.0, 1993.0, 1993-03-01)
(4.0, 975.0, "U.S.A.", "EAST", "EDUCATION", "FURNITURE", "SOFA", 1.0, 1993.0, 1993-01-01)
(9.0, 134.0, "U.S.A.", "EAST", "EDUCATION", "FURNITURE", "BED", 4.0, 1993.0, 1993-12-01)
(6.0, 915.0, "U.S.A.", "WEST", "EDUCATION", "OFFICE", "DESK", 2.0, 1993.0, 1993-04-01)
```

### ResultSet Metadata

There are simple functions to retrieve meta information about a ResultSet.
```
names(rs)
columns(rs)
size(rs)
```

### Conversion to DataFrame

It may be beneficial to convert the result set to DataFrame for more complex queries and manipulations.  

```julia
julia> df = DataFrame(columns(rs), names(rs));

julia> head(df)
6×10 DataFrames.DataFrame
│ Row │ ACTUAL │ PREDICT │ COUNTRY │ REGION │ DIVISION  │ PRODTYPE  │ PRODUCT │ QUARTER │ YEAR   │ MONTH      │
├─────┼────────┼─────────┼─────────┼────────┼───────────┼───────────┼─────────┼─────────┼────────┼────────────┤
│ 1   │ 925.0  │ 850.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 1.0     │ 1993.0 │ 1993-01-01 │
│ 2   │ 999.0  │ 297.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 1.0     │ 1993.0 │ 1993-02-01 │
│ 3   │ 608.0  │ 846.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 1.0     │ 1993.0 │ 1993-03-01 │
│ 4   │ 642.0  │ 533.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 2.0     │ 1993.0 │ 1993-04-01 │
│ 5   │ 656.0  │ 646.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 2.0     │ 1993.0 │ 1993-05-01 │
│ 6   │ 948.0  │ 486.0   │ CANADA  │ EAST   │ EDUCATION │ FURNITURE │ SOFA    │ 2.0     │ 1993.0 │ 1993-06-01 │
```


### Inclusion/Exclusion of Columns

**Column Inclusion**

It is always faster to read only the columns that you need.  The `include_columns` argument comes in handy:

```
julia> rs = readsas("productsales.sas7bdat", include_columns=[:YEAR, :MONTH, :PRODUCT, :ACTUAL])
Read productsales.sas7bdat with size 1440 x 4 in 0.00151 seconds
SASLib.ResultSet (1440 rows x 4 columns)
Columns 1:ACTUAL, 2:PRODUCT, 3:YEAR, 4:MONTH
1: 925.0, SOFA, 1993.0, 1993-01-01
2: 999.0, SOFA, 1993.0, 1993-02-01
3: 608.0, SOFA, 1993.0, 1993-03-01
4: 642.0, SOFA, 1993.0, 1993-04-01
5: 656.0, SOFA, 1993.0, 1993-05-01
⋮
```

**Column Exclusion**

Likewise, you can read all columns except the ones you don't want as specified in `exclude_columns` argument:

```
julia> rs = readsas("productsales.sas7bdat", exclude_columns=[:YEAR, :MONTH, :PRODUCT, :ACTUAL])
Read productsales.sas7bdat with size 1440 x 6 in 0.00265 seconds
SASLib.ResultSet (1440 rows x 6 columns)
Columns 1:PREDICT, 2:COUNTRY, 3:REGION, 4:DIVISION, 5:PRODTYPE, 6:QUARTER
1: 850.0, CANADA, EAST, EDUCATION, FURNITURE, 1.0
2: 297.0, CANADA, EAST, EDUCATION, FURNITURE, 1.0
3: 846.0, CANADA, EAST, EDUCATION, FURNITURE, 1.0
4: 533.0, CANADA, EAST, EDUCATION, FURNITURE, 2.0
5: 646.0, CANADA, EAST, EDUCATION, FURNITURE, 2.0
⋮
```

**Case Sensitivity and Column Number**

Column symbols are matched in a case insensitive manner with SAS column names.  

Both `include_columns` and `exclude_columns` accept column number.  In fact, you can mixed column symbols and column numbers as such:

```
julia> readsas("productsales.sas7bdat", include_columns=[:actual, :predict, 8, 9, 10])
Read productsales.sas7bdat with size 1440 x 5 in 0.16378 seconds
SASLib.ResultSet (1440 rows x 5 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:QUARTER, 4:YEAR, 5:MONTH
1: 925.0, 850.0, 1.0, 1993.0, 1993-01-01
2: 999.0, 297.0, 1.0, 1993.0, 1993-02-01
3: 608.0, 846.0, 1.0, 1993.0, 1993-03-01
4: 642.0, 533.0, 2.0, 1993.0, 1993-04-01
5: 656.0, 646.0, 2.0, 1993.0, 1993-05-01
⋮
```

### Incremental Reading

If you need to read files incrementally, you can use the `SASLib.open` function to obtain a handle of the file.  Then, use the `SASLib.read` function to fetch a number of rows.  Remember to close the handler with `SASLib.close` to avoid memory leak.

```julia
julia> handler = SASLib.open("productsales.sas7bdat")
SASLib.Handler[productsales.sas7bdat]

julia> rs = SASLib.read(handler, 2)
Read productsales.sas7bdat with size 2 x 10 in 0.06831 seconds
SASLib.ResultSet (2 rows x 10 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:COUNTRY, 4:REGION, 5:DIVISION, 6:PRODTYPE, 7:PRODUCT, 8:QUARTER, 9:YEAR, 10:MONTH
1: 925.0, 850.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-01-01
2: 999.0, 297.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-02-01

julia> rs = SASLib.read(handler, 3)
Read productsales.sas7bdat with size 3 x 10 in 0.00046 seconds
SASLib.ResultSet (3 rows x 10 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:COUNTRY, 4:REGION, 5:DIVISION, 6:PRODTYPE, 7:PRODUCT, 8:QUARTER, 9:YEAR, 10:MONTH
1: 608.0, 846.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-03-01
2: 642.0, 533.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 2.0, 1993.0, 1993-04-01
3: 656.0, 646.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 2.0, 1993.0, 1993-05-01

julia> SASLib.close(handler)
```

Note that there is no facility at the moment to jump and read a subset of rows.  Currently, SASLib always read from the beginning.

### String Column Constructor

By default, string columns are read into a special AbstractArray structure called `ObjectPool` in order to conserve memory space that might otherwise be wasted for duplicate string values.  SASLib tries to be smart -- when it encounters too many unique values (> 10%) in a large array (> 2000 rows), it falls back to a regular Julia array.

You can use a different array type (e.g. [CategoricalArray](https://github.com/JuliaData/CategoricalArrays.jl) or [PooledArray](https://github.com/JuliaComputing/PooledArrays.jl)) for any columns as you wish by specifying a `string_array_fn` parameter when reading the file.  This argument must be a Dict that maps a column symbol into a function that takes an integer argument and returns any array of that size.

Here's the normal case:

```
julia> rs = readsas("productsales.sas7bdat", include_columns=[:COUNTRY, :REGION]);
Read productsales.sas7bdat with size 1440 x 2 in 0.00193 seconds

julia> typeof.(columns(rs))
2-element Array{DataType,1}:
 SASLib.ObjectPool{String,UInt16}
 SASLib.ObjectPool{String,UInt16}
```

If you really want a regular String array, you can force SASLib to do so as such:

```
julia> rs = readsas("productsales.sas7bdat", include_columns=[:COUNTRY, :REGION],
                    string_array_fn=Dict(:COUNTRY => (n)->fill("",n)));
Read productsales.sas7bdat with size 1440 x 2 in 0.00333 seconds

julia> typeof.(columns(rs))
2-element Array{DataType,1}:
 Array{String,1}                 
 SASLib.ObjectPool{String,UInt16}
```

For convenience, `SASLib.REGULAR_STR_ARRAY` is a function that does exactly that.  In addition, if you need all columns to be configured the same then the key of the `string_array_fn` dict may be just the symbol `:_all_`. 

```
julia> rs = readsas("productsales.sas7bdat", include_columns=[:COUNTRY, :REGION],
                    string_array_fn=Dict(:_all_ => REGULAR_STR_ARRAY));
Read productsales.sas7bdat with size 1440 x 2 in 0.00063 seconds

julia> typeof.(columns(rs))
2-element Array{DataType,1}:
 Array{String,1}
 Array{String,1}
```

### Numeric Columns Constructor

In general, SASLib allocates native arrays when returning numerical column data.  However, you can provide a custom constructor so you would be able to either preallcoate the array or construct a different type of array.  The `number_array_fn` parameter is a Dict that maps  column symbols to the custom constructors.  Similar to `string_array_fn`, this Dict may be specified with a special symbol `:_all_` to indicate such constructor be used for all numeric columns.

Example - create SharedArray:
```
julia> rs = readsas("productsales.sas7bdat", include_columns=[:ACTUAL,:PREDICT], 
                          number_array_fn=Dict(:ACTUAL => (n)->SharedArray{Float64}(n)));
Read productsales.sas7bdat with size 1440 x 2 in 0.00385 seconds

julia> typeof.(columns(rs))
2-element Array{DataType,1}:
 SharedArray{Float64,1}
 Array{Float64,1}          
```

Example - preallocate arrays:
```
julia> A = zeros(1440, 2);

julia> f1(n) = @view A[:, 1];

julia> f2(n) = @view A[:, 2];

julia> readsas("productsales.sas7bdat", include_columns=[:ACTUAL,:PREDICT], 
               number_array_fn=Dict(:ACTUAL => f1, :PREDICT => f2));
Read productsales.sas7bdat with size 1440 x 2 in 0.00041 seconds

julia> A[1:5,:]
5×2 Array{Float64,2}:
 925.0  850.0
 999.0  297.0
 608.0  846.0
 642.0  533.0
 656.0  646.0
```

### Column Type Conversion

Often, you want a column to be an integer but the SAS7BDAT stores everything as Float64. Specifying the `column_type` argument does the conversion for you.

```
julia> rs = readsas("productsales.sas7bdat", column_types=Dict(:ACTUAL=>Int))
Read productsales.sas7bdat with size 1440 x 10 in 0.08043 seconds
SASLib.ResultSet (1440 rows x 10 columns)
Columns 1:ACTUAL, 2:PREDICT, 3:COUNTRY, 4:REGION, 5:DIVISION, 6:PRODTYPE, 7:PRODUCT, 8:QUARTER, 9:YEAR, 10:MONTH
1: 925, 850.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-01-01
2: 999, 297.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-02-01
3: 608, 846.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 1.0, 1993.0, 1993-03-01
4: 642, 533.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 2.0, 1993.0, 1993-04-01
5: 656, 646.0, CANADA, EAST, EDUCATION, FURNITURE, SOFA, 2.0, 1993.0, 1993-05-01

julia> typeof(rs[:ACTUAL])
Array{Int64,1}
```

### File Metadata

You may obtain meta data for a SAS data file using the `metadata` function.

```julia
julia> md = metadata("productsales.sas7bdat")
File: productsales.sas7bdat (1440 x 10)
1:ACTUAL(Float64)                5:DIVISION(String)               9:YEAR(Float64)
2:PREDICT(Float64)               6:PRODTYPE(String)               10:MONTH(Date/Missings.Missing)
3:COUNTRY(String)                7:PRODUCT(String) 
4:REGION(String)                 8:QUARTER(Float64)
```

It's OK to access the fields directly.
```julia
julia> fieldnames(SASLib.Metadata)
9-element Array{Symbol,1}:
 :filename   
 :encoding   
 :endianness 
 :compression
 :pagesize   
 :npages     
 :nrows      
 :ncols      
 :columnsinfo

julia> md = metadata("test3.sas7bdat");

julia> md.compression
:RDC
```

## Related Packages

[ReadStat.jl](https://github.com/davidanthoff/ReadStat.jl) uses the [ReadStat C-library](https://github.com/WizardMac/ReadStat).  However, ReadStat-C does not support reading RDC-compressed binary files.

[StatFiles.jl](https://github.com/davidanthoff/StatFiles.jl) is a higher-level package built on top of ReadStat.jl and implements the [FileIO](https://github.com/JuliaIO/FileIO.jl) interface.

[Python Pandas](https://github.com/pandas-dev/pandas) package has an implementation of SAS file reader that SASLib borrows heavily from.

## Credits

- Jared Hobbs, the author of the SAS reader code from Pandas.  See LICENSE_SAS7BDAT.md.
- [Evan Miller](https://github.com/evanmiller), the author of ReadStat C/C++ library.  See LICENSE_READSTAT.md.
- [David Anthoff](https://github.com/davidanthoff), who provided many valuable ideas at the early stage of development.
- [Tyler Beason](https://github.com/tbeason)
- [susabi](https://github.com/xiaodaigh)

I also want to thank all the active members at the [Julia Discourse community](https://discourse.julialang.org).  This project wouldn't be possible without all the help I got from the community.  That's the beauty of open-source development.
