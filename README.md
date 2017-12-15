# SASLib.jl

[![Build Status](https://travis-ci.org/tk3369/SASLib.jl.svg)](https://travis-ci.org/tk3369/SASLib.jl)
[![codecov.io](http://codecov.io/github/tk3369/SASLib.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/SASLib.jl?branch=master)

This is a port of Pandas' read_sas function.  

Porting Status
- [x] read sas7bdat files
- [ ] read xport files

To-do
- [ ] performance optimization (already better than Pandas but probably could still be improved)
- [ ] better unit testing and coverage
- [ ] better documentation

## Examples

```julia
using SASLib

df = readsas("test1.sas7bdat")

df = readsas("test1.sas7bdat", Dict(
        :encoding => "UTF-8"
        :chunksize => 0,
        :convert_dates => true,
        :convert_empty_string_to_missing => true,
        :convert_text => true,
        :convert_header_text => true
        ))
```

If you need to read files incrementally:

```julia
handler = SASLib.open("test1.sas7bdat")
rows = SASLib.read(handler, 100)   # read 100 rows
rows = SASLib.read(handler, 200)   # read next 200 rows
SASLib.close(handler)              # remember to close the handler when done
```
