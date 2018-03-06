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
- `columnsinfo`: vector of column symbols and their respective types
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
    columnsinfo::Vector{Pair{Symbol, Type}}
end

"""
Return metadata of a SAS data file.  See `SASLib.Metadata`.
"""
function metadata(fname::AbstractString)
    h = nothing
    try
        h = SASLib.open(fname, verbose_level = 0)
        rs = read(h, 1)
        _metadata(h, rs)
    finally
        h != nothing && SASLib.close(h)
    end
end

# construct Metadata struct using handler & result set data
function _metadata(h::Handler, rs::ResultSet)
    cmp = h.compression == compression_method_rle ?
            :RLE : (h.compression == compression_method_rdc ? :RDC : :none)
    Metadata(
        h.config.filename,
        h.file_encoding,
        h.file_endianness,
        cmp,
        h.page_length,
        h.page_count,
        h.row_count,
        h.column_count,
        [Pair(x, eltype(rs[x])) for x in names(rs)]
    )
end

# pretty print
function Base.show(io::IO, md::Metadata)
    println(io, "File: ", md.filename, " (", md.nrows, " x ", md.ncols, ")")
    displaytable(io, colfmt(md); index=true)
end

# Column display format
function colfmt(md::Metadata)
    [string(first(p), "(", typesfmt(typesof(last(p))), 
        ")") for p in md.columnsinfo]
end

# Compact types format
# e.g. (Date, Missings.Missing) => "Date/Missings.Missing"
function typesfmt(ty::Tuple; excludemissing = false)
    ar = excludemissing ?
        collect(Iterators.filter(x -> x != Missings.Missing, ty)) : [ty...]
    join(string.(ar), "/")
end

# Extract types from a Union
# e.g.
#   Union{Int64, Int32, Float32} => (Int64, Int32, Float32)
#   Int32 => (Int32,)
function typesof(ty::Type)
    if ty isa Union
        y = typesof(ty.b)
        y isa Tuple ? (ty.a, y...) : (ty.a, y)
    else
        (ty,)
    end
end