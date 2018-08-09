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
columns(rs::ResultSet) = rs.columns
Base.names(rs::ResultSet) = rs.names
Base.size(rs::ResultSet) = rs.size
Base.size(rs::ResultSet, i::Integer) = rs.size[i]

# Size displayed as a string 
sizestr(rs::ResultSet) = string(size(rs, 1)) * " rows x " * string(size(rs, 2)) * " columns"

# find index for the column symbol
function symindex(rs::ResultSet, s::Symbol) 
    n = findfirst(x -> x == s, rs.names)
    n == 0 && error("column symbol not found: $s")
    n
end

# Direct cell access
Base.getindex(rs::ResultSet, i::Integer, j::Integer) = rs.columns[j][i]
Base.getindex(rs::ResultSet, i::Integer, s::Symbol) = rs.columns[symindex(rs, s)][i]
Base.setindex!(rs::ResultSet, val, i::Integer, j::Integer) = rs.columns[j][i] = val
Base.setindex!(rs::ResultSet, val, i::Integer, s::Symbol) = rs.columns[symindex(rs, s)][i] = val

# Return a single row as a tuple
Base.getindex(rs::ResultSet, i::Integer) = Tuple([c[i] for c in rs.columns])

# Return a single row as a tuple
Base.getindex(rs::ResultSet, c::Symbol) = rs.columns[symindex(rs, c)]

# index by row range => returns ResultSet object
function Base.getindex(rs::ResultSet, r::UnitRange{Int})
    ResultSet(map(x -> view(x, r), rs.columns), rs.names, (length(r), size(rs, 2)))
end

# index by columns => returns ResultSet object
function Base.getindex(rs::ResultSet, ss::Symbol...)
    v = Int[]
    for (idx, nam) in enumerate(rs.names)
        nam in ss && push!(v, idx)
    end
    ResultSet(rs.columns[v], rs.names[v], (size(rs, 1), length(v)))
end

# Iterators
@static if VERSION > v"0.7-"
    Base.iterate(rs::ResultSet, i=1) = i > size(rs,1) ? nothing : (rs[i], i+1)
else
    Base.start(rs::ResultSet) = 1
    Base.done(rs::ResultSet, i::Int) = i > size(rs, 1)
    Base.next(rs::ResultSet, i::Int) = (rs[i], i+1)
end

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
        print(io, i, ":", rs.names[i])
    end
    m < length(rs.names) && print(io, " …")
    println(io)
    for i in 1:n
        print(io, i, ": ")
        for j in 1:m
            j > 1 && print(io, ", ")
            print(io, rs.columns[j][i])
        end
        println(io)
    end
    n < size(rs, 1) && println(io, "⋮")
end

# IteratableTables
# IteratorInterfaceExtensions.isiterable(::ResultSet) = true

# TableTraits.isiterabletable(::ResultSet) = true

# function IteratorInterfaceExtensions.getiterator(rs::ResultSet)
#     TableTraitsUtils.create_tableiterator(rs.columns, rs.names)
# end
