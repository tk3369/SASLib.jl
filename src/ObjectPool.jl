"""
ObjectPool is a fixed-size one-dimensional array that does not store 
any duplicate copies of the same object.  So the benefit is space-efficiency. 
The tradeoff is the time used to maintain the index.  
This is useful for denormalized data frames where string values
may be repeated many times.

An ObjectPool must be initialize with a default value and a fixed
array size.  If your requirement does not fit such assumptions, 
you may want to look into using `PooledArrays` or 
`CategoricalArrays` package instead.

The implementation is very primitive and is tailor for application
that knows exactly how much memory to allocate.
"""
mutable struct ObjectPool{T, S <: Unsigned} <: AbstractArray{T, 1}
    pool::Array{T}             # maintains the pool of unique things
    idx::Array{S}              # index references into `pool`
    indexcache::Dict{T, S}     # dict for fast lookups (K=object, V=index)
    uniqueitemscount::Int64    # how many items in `pool`, always start with 1
    itemscount::Int64          # how many items perceived in this array
    capacity::Int64            # max number of items in the pool
end

# Initially, there is only one item in the pool and the `idx` array has
# elements all pointing to that one default vaue.  The dictionary `indexcache`
# also has one item that points to that one value.  Hence `uniqueitemcount`
# would be 1 and `itemscount` would be `n`.
function ObjectPool{T, S}(val::T, n::Integer) where {T, S <: Unsigned} 
    # Note: 64-bit case is constrainted by Int64 type (for convenience)
    maxsize = ifelse(S == UInt8, 2 << 7 - 1,
                ifelse(S == UInt16, 2 << 15 - 1,
                    ifelse(S == UInt32, 2 << 31 - 1, 
                        2 << 62 - 1))) 
    ObjectPool{T, S}([val], fill(1, n), Dict(val => 1), 1, n, maxsize)
end

# If the value already exist in the pool then just the index value is stored.
function Base.setindex!(op::ObjectPool, val::T, i::Integer) where T
    if haskey(op.indexcache, val)
        # The value `val` already exists in the cache.  
        # Just set the array element to the index value from cache.
        op.idx[i] = op.indexcache[val]
    else
        if op.uniqueitemscount >= op.capacity
            throw(BoundsError("Exceeded pool capacity $(op.capacity). Consider using a larger pool size e.g. UInt32."))
        end
        # Encountered a new value `val`:
        # 1. add ot the object pool array
        # 2. increment the number of unique items
        # 3. store the new index in the cache
        # 4. set the array element with the new index value
        push!(op.pool, val)
        op.uniqueitemscount += 1
        op.indexcache[val] = op.uniqueitemscount
        op.idx[i] = op.uniqueitemscount
    end
    op
end

# AbstractArray trait 
# Base.IndexStyle(::Type{<:ObjectPool}) = IndexLinear()

# single indexing
Base.getindex(op::ObjectPool, i::Integer) = op.pool[op.idx[convert(Int, i)]]

# general sizes
Base.size(op::ObjectPool)   = (op.itemscount, )
# Base.length(op::ObjectPool) = op.itemscount
# Base.endof(op::ObjectPool)  = op.itemscount

# typing
#Base.eltype(op::ObjectPool) = eltype(op.pool)

# make it iterable
# Base.start(op::ObjectPool)  = 1
# Base.next(op::ObjectPool, state) = (op.pool[op.idx[state]], state + 1)
# Base.done(op::ObjectPool, state) = state > op.itemscount

# custom printing
# function Base.show(io::IO, op::ObjectPool)
#     L = op.itemscount
#     print(io, "$L-element ObjectPool with $(op.uniqueitemscount) unique items:\n")
#     if L > 20
#         for i in 1:10  print(io, " ", op[i], "\n") end
#         print(io, " ⋮\n")
#         for i in L-9:L print(io, " ", op[i], "\n") end
#     else
#         for i in 1:L   print(io, " ", op[i], "\n") end
#     end
# end
