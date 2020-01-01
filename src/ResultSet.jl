#using IteratorInterfaceExtensions, TableTraits, TableTraitsUtils

"""
ResultSet is the primary object that represents data returned from 
reading a SAS data file.  ResultSet implements the Base.Iteration
interface as well as the IterableTables.jl interface.

*Fields*
- `columns`: a vector of columns, each being a vector itself
- `names`: a vector of column symbols
- `size`: a tuple (nrows, ncols)

*Accessors*
- `columns(::ResultSet)`
- `names(::ResultSet)`
- `size(::ResultSet)`
- `size(::ResultSet, dim::Integer)`

*Single Row/Column Indexing*
- `rs[i]` returns a tuple for row `i`
- `rs[:c]` returns a vector for column `c`

*Multiple Row/Column Indexing*
- `rs[i:j]` returns a view of ResultSet with rows between `i` and `j`
- `rs[:c...]` returns a view of ResultSet with columns specified e.g. `rs[:A, :B]`

*Cell Indexing*
- `rs[i,j]` returns a single value for row `i` column `j`
- `rs[i,:c]` returns a single value for row `i` column `c`
- Specific cell can be assigned using the above indexing methods
"""
struct ResultSet
    columns::AbstractVector{AbstractVector}
    names::AbstractVector{Symbol}
    size::NTuple{2, Int}
    ResultSet() = new([], [], (0,0))  # special case
    ResultSet(c,n,s) = new(c, n, s)
end

# exports
export columns

# accessors 
columns(rs::ResultSet) = getfield(rs, :columns)
Base.names(rs::ResultSet) = getfield(rs, :names)

Base.size(rs::ResultSet) = getfield(rs, :size)
Base.size(rs::ResultSet, i::Integer) = getfield(rs, :size)[i]
Base.length(rs::ResultSet) = getfield(rs, :size)[1]

# Size displayed as a string 
sizestr(rs::ResultSet) = string(size(rs, 1)) * " rows x " * string(size(rs, 2)) * " columns"

# find index for the column symbol
function symindex(rs::ResultSet, s::Symbol) 
    n = findfirst(x -> x == s, names(rs))
    n == 0 && error("column symbol not found: $s")
    n
end

# Direct cell access
Base.getindex(rs::ResultSet, i::Integer, j::Integer) = columns(rs)[j][i]
Base.getindex(rs::ResultSet, i::Integer, s::Symbol) = columns(rs)[symindex(rs, s)][i]
Base.setindex!(rs::ResultSet, val, i::Integer, j::Integer) = columns(rs)[j][i] = val
Base.setindex!(rs::ResultSet, val, i::Integer, s::Symbol) = columns(rs)[symindex(rs, s)][i] = val

# Return a single row as a named tuple
Base.getindex(rs::ResultSet, i::Integer) = 
    NamedTuple{Tuple(names(rs))}([c[i] for c in columns(rs)])

# Return a single column
Base.getindex(rs::ResultSet, c::Symbol) = columns(rs)[symindex(rs, c)]

# index by row range => returns ResultSet object
function Base.getindex(rs::ResultSet, r::UnitRange{Int})
    ResultSet(map(x -> view(x, r), columns(rs)), names(rs), (length(r), size(rs, 2)))
end

# index by columns => returns ResultSet object
function Base.getindex(rs::ResultSet, ss::Symbol...)
    v = Int[]
    for (idx, nam) in enumerate(names(rs))
        nam in ss && push!(v, idx)
    end
    ResultSet(columns(rs)[v], names(rs)[v], (size(rs, 1), length(v)))
end

# Each property must represent a column to satisfy Tables.jl Columns interface
Base.propertynames(rs::ResultSet) = names(rs)

function Base.getproperty(rs::ResultSet, s::Symbol)
    s ∈ names(rs) && return rs[s]
    error("Column $s not found")
end


# Iterators
Base.iterate(rs::ResultSet, i=1) = i > size(rs,1) ? nothing : (rs[i], i+1)

# Display ResultSet object
function Base.show(io::IO, rs::ResultSet) 
    println(io, "SASLib.ResultSet (", sizestr(rs), ")")
    max_rows = 5
    max_cols = 10
    n = min(size(rs, 1), max_rows)
    m = min(size(rs, 2), max_cols)
    (n < 1 || m < 1) && return
    print(io, "Columns ")
    for i in 1:m
        i > 1 && print(io, ", ")
        print(io, i, ":", names(rs)[i])
    end
    m < length(names(rs)) && print(io, " …")
    println(io)
    for i in 1:n
        print(io, i, ": ")
        for j in 1:m
            j > 1 && print(io, ", ")
            print(io, columns(rs)[j][i])
        end
        println(io)
    end
    n < size(rs, 1) && println(io, "⋮")
end

