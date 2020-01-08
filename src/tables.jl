Tables.istable(::Type{<:ResultSet}) = true

Tables.rowaccess(::Type{<:ResultSet}) = true
Tables.columnaccess(::Type{<:ResultSet}) = true

Tables.rows(rs::ResultSet) = rs
Tables.columns(rs::ResultSet) = rs

Tables.schema(rs::ResultSet) = Tables.Schema(names(rs), eltype.(columns(rs)))

IteratorInterfaceExtensions.getiterator(rs::ResultSet) = Tables.datavaluerows(rs)
TableTraits.isiterabletable(x::ResultSet) = true
