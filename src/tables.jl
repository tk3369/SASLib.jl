# This file implements Tables interface and provide compatibility 
# to the Queryverse ecosystem.

# ----------------------------------------------------------------------------- 
# Tables.jl implementation

Tables.istable(::Type{<:ResultSet}) = true

# AbstractColumns interface
Tables.columnaccess(::Type{<:ResultSet}) = true
Tables.columns(rs::ResultSet) = rs
Tables.getcolumn(rs::ResultSet, i::Int) = rs[names(rs)[i]]

# AbstractRow interface
Tables.rowaccess(::Type{<:ResultSet}) = true
Tables.rows(rs::ResultSet) = rs

# Schema definition
Tables.schema(rs::ResultSet) = Tables.Schema(names(rs), eltype.(columns(rs)))

# ----------------------------------------------------------------------------- 
# Queryverse compatibility

IteratorInterfaceExtensions.getiterator(rs::ResultSet) = Tables.datavaluerows(rs)
TableTraits.isiterabletable(x::ResultSet) = true
