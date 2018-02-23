export metadata

"""
Metadata contains information about a SAS data file.

*Fields*
- `filename`: file name/path of the SAS data set
- `encoding`: file encoding e.g. "ISO8859-1"
- `endianness`: either `:LittleEndian`` or `:BigEndian`
- `compression`: could be `:RLE`, `:RDC`, or `:none`
- `pagesize`: size of each data page in bytes
- `npages`: number of pages in the file
- `nrows`: number of data rows in the file
- `ncols`: number of data columns in the file
- `columnsinfo`: vector of column symbols and their respective types (Float64 or String)
"""
struct Metadata
    filename::AbstractString
    encoding::AbstractString          # e.g. "ISO8859-1"
    endianness::Symbol                # :LittleEndian, :BigEndian
    compression::Symbol               # :RDC, :RLE
    pagesize::Int
    npages::Int
    nrows::Int
    ncols::Int
    columnsinfo::Vector{Pair{Symbol, DataType}}  # Float64 or String
end

function metadata(h::Handler)
    ci = [Pair(h.column_symbols[i], 
               h.column_types[i] == column_type_decimal ? Float64 : String) 
            for i in 1:h.column_count]
    cmp = ifelse(h.compression == compression_method_rle, :RLE,
     ifelse(h.compression == compression_method_rdc, :RDC, :none))
    Metadata(
        h.config.filename,
        h.file_encoding,
        h.file_endianness,
        cmp,
        h.page_length,
        h.page_count,
        h.row_count,
        h.column_count,
        ci
    )
end

function metadata(fname::AbstractString)
    local h
    try
        h = SASLib.open(fname)
        metadata(h)
    finally
        SASLib.close(h)
    end
end