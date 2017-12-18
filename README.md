# SASLib.jl

[![Build Status](https://travis-ci.org/tk3369/SASLib.jl.svg)](https://travis-ci.org/tk3369/SASLib.jl)
[![codecov.io](http://codecov.io/github/tk3369/SASLib.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/SASLib.jl?branch=master)

This is a port of Pandas' read_sas function.  

Porting Status
- [x] read sas7bdat files
- [ ] read xport files

To-do
- [ ] performance optimization
- [ ] better unit testing and coverage
- [ ] better documentation

## Examples

Use the `readsas` function to read the file.  The result is a dictionary of various information about the file as well as the data itself.

```julia
julia> using SASLib

julia> x = readsas("test1.sas7bdat")
Read data set of size 10 x 100 in 0.019 seconds
Dict{Symbol,Any} with 16 entries:
  :filename             => "test1.sas7bdat"
  :page_length          => 65536
  :file_encoding        => "wlatin1"
  :system_endianness    => :LittleEndian
  :ncols                => 100
  :column_types         => DataType[Float64, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64  …  Float64, Float64…
  :data                 => Dict{Any,Any}(Pair{Any,Any}(:Column60, [2987.0, 8194.0, 9820.0, 8252.0, 9640.0, 9168.0, 7547.0, 1419.0, 4884.0, NaN])…
  :perf_type_conversion => 0.0052096
  :page_count           => 1
  :column_names         => String["Column60", "Column42", "Column68", "Column35", "Column33", "Column1", "Column41", "Column16", "Column72", "Co…
  :column_symbols       => Symbol[:Column60, :Column42, :Column68, :Column35, :Column33, :Column1, :Column41, :Column16, :Column72, :Column19  ……
  :column_lengths       => [8, 9, 8, 8, 8, 9, 8, 8, 8, 9  …  8, 8, 8, 5, 8, 8, 8, 9, 8, 8]
  :file_endianness      => :LittleEndian
  :nrows                => 10
  :perf_read_data       => 0.00612195
  :column_offsets       => [0, 600, 8, 16, 24, 609, 32, 40, 48, 618  …  536, 544, 552, 795, 560, 568, 576, 800, 584, 592]
```

Number of columns and rows are returned as in `:ncols` and `:nrows` respectively.

The data, reference by `:data` key, is represented as a Dict object with the column symbol as the key.

```juia
julia> x[:data][:Column1]
10-element Array{Float64,1}:
   0.636
   0.283
   0.452
   0.557
   0.138
   0.948
   0.162
   0.148
 NaN    
   0.663
```

If you really like DataFrame, you can easily convert as such:

```julia
julia> using DataFrames

julia> df = DataFrame(x[:data]);

julia> df[:, 1:5]
10×5 DataFrames.DataFrame
│ Row │ Column1 │ Column10    │ Column100 │ Column11 │ Column12   │
├─────┼─────────┼─────────────┼───────────┼──────────┼────────────┤
│ 1   │ 0.636   │ "apple"     │ 3230.0    │ NaN      │ 1986-07-20 │
│ 2   │ 0.283   │ "apple"     │ 4904.0    │ 22.0     │ 1983-07-15 │
│ 3   │ 0.452   │ "apple"     │ NaN       │ 7.0      │ 1973-11-27 │
│ 4   │ 0.557   │ "dog"       │ 8566.0    │ 26.0     │ 1967-01-20 │
│ 5   │ 0.138   │ "crocodile" │ 894.0     │ 11.0     │ 1970-11-29 │
│ 6   │ 0.948   │ "crocodile" │ 6088.0    │ 27.0     │ 1963-01-09 │
│ 7   │ 0.162   │ ""          │ 6122.0    │ NaN      │ 1979-10-18 │
│ 8   │ 0.148   │ "crocodile" │ 2570.0    │ 5.0      │ 1961-03-15 │
│ 9   │ NaN     │ "pear"      │ 2709.0    │ 12.0     │ 1964-06-15 │
│ 10  │ 0.663   │ "pear"      │ NaN       │ 16.0     │ 1985-01-28 │
```

If you need to read files incrementally:

```julia
handler = SASLib.open("test1.sas7bdat")
results = SASLib.read(handler, 3)   # read 3 rows
results = SASLib.read(handler, 4)   # read next 4 rows
SASLib.close(handler)              # remember to close the handler when done
```
