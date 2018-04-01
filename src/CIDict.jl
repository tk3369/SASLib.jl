# Case insensitive Dict - a simple wrapper over Dict

struct CIDict{K, T}

    dct::Dict{K, T}

    # type checking
    check(K) = K <: AbstractString || K <: Symbol || 
        throw(ArgumentError("Key must be Symbol or String type"))

    # constructors
    CIDict{K, T}() where {K,T} = (check(K); new(Dict{K,T}()))
    CIDict{K, T}(d::Dict{K,T}) where {K,T} = begin
        check(K)
        d2 = Dict{K,T}()
        for k in keys(d)
            d2[lcase(k)] = d[k]
        end
        new(d2)
    end
end

lcase(s::Symbol) = Symbol(lowercase(String(s)))
lcase(s::AbstractString) = lowercase(s)

Base.getindex(d::CIDict, s::Symbol) = d.dct[lcase(s)]
Base.getindex(d::CIDict, s::String) = d.dct[lcase(s)]

Base.setindex!(d::CIDict, v, s::Symbol) = d.dct[lcase(s)] = v
Base.setindex!(d::CIDict, v, s::String) = d.dct[lcase(s)] = v

Base.haskey(d::CIDict, s::Symbol) = haskey(d.dct, lcase(s))
Base.haskey(d::CIDict, s::String) = haskey(d.dct, lcase(s))

Base.keys(d::CIDict) = keys(d.dct)
Base.values(d::CIDict) = values(d.dct)

Base.start(d::CIDict) = start(d.dct)
Base.next(d::CIDict, i::Int) = next(d.dct, i)
Base.done(d::CIDict, i::Int) = done(d.dct, i)

Base.show(io::IO, d::CIDict) = show(io, d.dct)

Base.length(d::CIDict) = length(d.dct)
