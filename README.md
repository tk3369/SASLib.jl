# SASLib

[![Build Status](https://travis-ci.org/tk3369/SASLib.jl.svg)](https://travis-ci.org/tk3369/SASLib.jl)
[![codecov.io](http://codecov.io/github/tk3369/SASLib.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/SASLib.jl?branch=master)

This is a port of Pandas' read_sas function.  

It is still a work in progress but at least it can read one test file :-)

## Example

```julia
using SASLib

df = readsas("test1.sas7bdat")

df = readsas("test1.sas7bdat"; config=Dict(
        :encoding => "UTF-8"
        :chunksize => 0,
        :convert_dates => true,
        :convert_empty_string_to_missing => true,
        :convert_text => true,
        :convert_header_text => true
        ))
```
