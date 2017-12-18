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

Use the `readsas` function to read the file.

```julia
julia> using SASLib

julia> x = readsas("test1.sas7bdat")
INFO: Read data set of size 10 x 100 in 0.017 seconds
Dict{Symbol,Any} with 10 entries:
  :file_endianness     => :LittleEndian
  :ncols               => 100
  :filename            => "test1.sas7bdat"
  :nrows               => 10
  :perf_typeconversion => 0.00993576
  :perf_readdata       => 0.00620258
  :file_pagecount      => 1
  :file_pagelength     => 65536
  :data                => Dict{Any,Any}(Pair{Any,Any}(:Column60, [2987.0, 8194.0, 9820.0, 8252.0, 9640.0, 9168.0, 7547.0, 1419.0, 4884.0, NaN]),…
  :file_encoding       => "wlatin1"
```

You can use the data by referencing the key `:data`, for which the value is another Dict object with the column name as the key.

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
