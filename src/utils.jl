"""
Strip from the right end of the `bytes` array for any byte that matches the ones
specified in the `remove` argument.  See Python's bytes.rstrip function.
"""
function brstrip(bytes::AbstractVector{UInt8}, remove::AbstractVector{UInt8})
    for i in length(bytes):-1:1
        x = bytes[i]
        found = false
        for m in remove
            if x == m
                found = true
                break 
            end
        end
        if !found
            return bytes[1:i]
        end
    end
    return Vector{UInt8}()
end

# """
# Faster version of rstrip (slightly modified version from julia master branch)
# """
# function rstrip2(s::String)
#     i = endof(s)
#     while 1 ≤ i
#         c = s[i]
#         j = prevind(s, i)
#         c == ' ' || return s[1:i]
#         i = j
#     end
#     EMPTY_STRING
# end

"""
Find needle in the haystack with both `Vector{UInt8}` type arguments.
"""
function contains(haystack::AbstractVector{UInt8}, needle::AbstractVector{UInt8})
    hlen = length(haystack)
    nlen = length(needle)
    if hlen >= nlen
        for i in 1:hlen-nlen+1
            if haystack[i:i+nlen-1] == needle
                return true
            end
        end
    end
    return false
end

# Fast implementation to `reinterpret` int/floats
# See https://discourse.julialang.org/t/newbie-question-convert-two-8-byte-values-into-a-single-16-byte-value/7662/5

# Version a.  Original implementation... slow.
# """
# Byte swap is needed only if file the array represent a different endianness
# than the system.  This function does not make any assumption and the caller
# is expected to pass `true` to the `swap` argument when needed.
# """
# function convertfloat64a(bytes::Vector{UInt8}, swap::Bool)
#     # global count_a
#     # count_a::Int64 += 1
#     values = [bytes[i:i+8-1] for i in 1:8:length(bytes)]
#     values = map(x -> reinterpret(Float64, x)[1], values)
#     swap ? bswap.(values) : values
# end

# Version b.  Should be a lot faster. 
# julia> @btime convertfloat64b(r, :LittleEndian);
#   370.677 μs (98 allocations: 395.41 KiB)
# """
# It turns out that `reinterpret` consider a single UInt64 as BigEndian 
# Hence it's necessary to swap bytes if the array is in LittleEndian convention.
# This function does not make any assumption and the caller
# is expected to pass `true` to the `swap` argument when needed.
# """
# function convertfloat64b(bytes::Vector{UInt8}, endianess::Symbol) 
#     # global count_b
#     # count_b::Int64 += 1
#     v = endianess == :LittleEndian ? reverse(bytes) : bytes
#     c = convertint64.(v[1:8:end],v[2:8:end],v[3:8:end],v[4:8:end],
#             v[5:8:end], v[6:8:end], v[7:8:end], v[8:8:end])
#     r = reinterpret.(Float64, c)
#     endianess == :LittleEndian ? reverse(r) : r
# end

# Version c
# julia> @btime convertfloat64c(r, :LittleEndian);
#   75.835 μs (2 allocations: 78.20 KiB)
# function convertfloat64c(bytes::Vector{UInt8}, endianess::Symbol) 
#     L = length(bytes)
#     n = div(L, 8)               # numbers to convert
#     r = zeros(Float64, n)       # results
#     j = 1                       # result index
#     @inbounds for i in 1:8:L
#         if endianess == :LittleEndian
#             r[j] = reinterpret(Float64, convertint64(
#                         bytes[i+7], bytes[i+6], bytes[i+5], bytes[i+4],
#                         bytes[i+3], bytes[i+2], bytes[i+1], bytes[i]))
#         else
#             r[j] = reinterpret(Float64, convertint64(
#                         bytes[i],   bytes[i+1], bytes[i+2], bytes[i+3],
#                         bytes[i+4], bytes[i+5], bytes[i+6], bytes[i+7]))
#         end
#         j += 1
#     end
#     r
# end

# Version d
# julia> @btime convertfloat64d(r, :LittleEndian);
#   184.463 μs (4 allocations: 156.47 KiB)
# function convertfloat64d(bytes::Vector{UInt8}, endianess::Symbol) 
#     if endianess == :LittleEndian
#         v = reverse(bytes) 
#     else 
#         v = bytes
#     end
#     L = length(bytes)
#     n = div(L, 8)               # numbers to convert
#     r = zeros(Float64, n)       # results
#     j = n                       # result index
#     for i in 1:8:L
#         r[j] = reinterpret(Float64, convertint64(
#             v[i],   v[i+1], v[i+2], v[i+3],
#             v[i+4], v[i+5], v[i+6], v[i+7]))
#         j -= 1
#     end
#     r
# end

# Version e - same as version c except that it does bit-shifting
# inline here in a new way.
# julia> @btime convertfloat64e(r, :LittleEndian);
#   174.685 μs (2 allocations: 78.20 KiB)
# function convertfloat64e(bytes::Vector{UInt8}, endianess::Symbol) 
#     L = length(bytes)
#     n = div(L, 8)               # numbers to convert
#     r = zeros(Float64, n)       # results
#     j = 1                       # result index
#     for i in 1:8:L
#         v = UInt64(0)
#         if endianess == :LittleEndian
#             for k in 7:-1:1
#                 v = (v | bytes[i + k]) << 8 
#             end
#             v |= bytes[i]
#         else
#             for k in 0:6
#                 v = (v | bytes[i + k]) << 8
#             end
#             v |= bytes[i + 7]
#         end
#         r[j] = reinterpret(Float64, v)
#         j += 1
#     end
#     r
# end

# Version f.  Best one so far!
# julia> @btime convertfloat64f(r, :LittleEndian)
#   35.132 μs (2 allocations: 78.20 KiB)
# 
# results will be updated directly in the provided array `r`
function convertfloat64f!(r::AbstractVector{Float64}, bytes::Vector{UInt8}, endianess::Symbol) 
    L = length(bytes)
    n = div(L, 8)               # numbers to convert
    j = 1                       # result index
    @inbounds for i in 1:8:L
        if endianess == :LittleEndian
            r[j] = reinterpret(Float64, 
                        UInt64(bytes[i+7]) << 56 | 
                        UInt64(bytes[i+6]) << 48 |
                        UInt64(bytes[i+5]) << 40 |
                        UInt64(bytes[i+4]) << 32 |
                        UInt64(bytes[i+3]) << 24 |
                        UInt64(bytes[i+2]) << 16 |
                        UInt64(bytes[i+1]) << 8  | 
                        UInt64(bytes[i]))
        else
            r[j] = reinterpret(Float64, 
                        UInt64(bytes[i]) << 56 | 
                        UInt64(bytes[i+1]) << 48 |
                        UInt64(bytes[i+2]) << 40 |
                        UInt64(bytes[i+3]) << 32 |
                        UInt64(bytes[i+4]) << 24 |
                        UInt64(bytes[i+5]) << 16 |
                        UInt64(bytes[i+6]) << 8  | 
                        UInt64(bytes[i+7]))
        end
        j += 1
    end
    r
end

# Conversion routines for 1,2,4,8-byte words into a single 64-bit integer
@inline function convertint64B(a::UInt8,b::UInt8,c::UInt8,d::UInt8,e::UInt8,f::UInt8,g::UInt8,h::UInt8)
    (Int64(a) << 56) | (Int64(b) << 48) | (Int64(c) << 40) | (Int64(d) << 32) | 
    (Int64(e) << 24) | (Int64(f) << 16) | (Int64(g) << 8)  |  Int64(h)
end
@inline function convertint64L(a::UInt8,b::UInt8,c::UInt8,d::UInt8,e::UInt8,f::UInt8,g::UInt8,h::UInt8)
    (Int64(h) << 56) | (Int64(g) << 48) | (Int64(f) << 40) | (Int64(e) << 32) | 
    (Int64(d) << 24) | (Int64(c) << 16) | (Int64(b) << 8)  |  Int64(a)
end
@inline function convertint64B(a::UInt8,b::UInt8,c::UInt8,d::UInt8)
    (Int64(a) << 24) | (Int64(b) << 16) | (Int64(c) << 8)  |  Int64(d)
end
@inline function convertint64L(a::UInt8,b::UInt8,c::UInt8,d::UInt8)
    (Int64(d) << 24) | (Int64(c) << 16) | (Int64(b) << 8)  |  Int64(a)
end
@inline function convertint64B(a::UInt8,b::UInt8)
    (Int64(a) << 8)  |  Int64(b)
end
@inline function convertint64L(a::UInt8,b::UInt8)
    (Int64(b) << 8)  | Int64(a)
end

# this version is slightly slower 
# function convertint64b(a::UInt8,b::UInt8,c::UInt8,d::UInt8,e::UInt8,f::UInt8,g::UInt8,h::UInt8)
#     v = UInt64(a) << 8
#     v |= b ; v <<= 8
#     v |= c ; v <<= 8
#     v |= d ; v <<= 8
#     v |= e ; v <<= 8
#     v |= f ; v <<= 8
#     v |= g ; v <<= 8
#     v |= h 
#     v
# end


# TODO cannot use AbstractString for some reasons
# """
# Concatenate an array of strings to a single string
# """
# concatenate(strArray::Vector{T} where T <: AbstractString, separator=",") = 
#     foldl((x, y) -> *(x, y, separator), "", strArray)[1:end-length(separator)]

# """
# Convert a dictionary to an array of k=>v strings 
# """
# stringarray(dict::Dict) = 
#     ["$x => $y" for (x, y) in dict]

