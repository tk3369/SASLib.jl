# SASLib

This is a port of Pandas' read_sas function.  

It is still a work in progress but at least it can read one test file :-)

## Example

```julia
import SASLib

df = readsas("whatever.sas7bdat")

df = readsas("whatever.sas7bdat", Dict(
        :encoding => "UTF-8"
        :chunksize => 0,
        :convert_dates => true,
        :convert_empty_string_to_missing => true,
        :convert_text => true,
        :convert_header_text => true
        ))
```
