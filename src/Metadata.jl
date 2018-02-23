export metadata

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