"""
Strip from the right end of the `bytes` array for any byte that matches the ones
specified in the `remove` argument.  See Python's bytes.rstrip function.
"""
function brstrip(bytes::Vector{UInt8}, remove::Vector{UInt8})
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
#brstrip(b"\x01\x02\x03", b"\x03")

"""
Find needle in the haystack with both `Vector{UInt8}` type arguments.
"""
function Base.contains(haystack::Vector{UInt8}, needle::Vector{UInt8})
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
# contains(b"123", b"123")
# contains(b"123456", b"123")
# contains(b"123456", b"234")
# contains(b"123456", b"456")
# contains(b"123456", b"567")
# contains(b"123456", b"xxx")

# Fast implementation to `reinterpret` int/floats
# See https://discourse.julialang.org/t/newbie-question-convert-two-8-byte-values-into-a-single-16-byte-value/7662/5

# Version a.  Original implementation... slow.
"""
Byte swap is needed only if file the array represent a different endianness
than the system.  This function does not make any assumption and the caller
is expected to pass `true` to the `swap` argument when needed.
"""
function convertfloat64a(bytes::Vector{UInt8}, swap::Bool)
    # global count_a
    # count_a::Int64 += 1
    values = [bytes[i:i+8-1] for i in 1:8:length(bytes)]
    values = map(x -> reinterpret(Float64, x)[1], values)
    swap ? bswap.(values) : values
end

# Version b.  Should be a lot faster.  
"""
It turns out that `reinterpret` consider a single UInt64 as BigEndian 
Hence it's necessary to swap bytes if the array is in LittleEndian convention.
This function does not make any assumption and the caller
is expected to pass `true` to the `swap` argument when needed.
"""
function convertfloat64b(bytes::Vector{UInt8}, endianess::Symbol) 
    # global count_b
    # count_b::Int64 += 1
    v = endianess == :LittleEndian ? reverse(bytes) : bytes
    c = convertint64.(v[1:8:end],v[2:8:end],v[3:8:end],v[4:8:end],
            v[5:8:end], v[6:8:end], v[7:8:end], v[8:8:end])
    r = reinterpret.(Float64, c)
    endianess == :LittleEndian ? reverse(r) : r
end

"""
Take 8 bytes and convert them into a UInt64 type.  The order is preserved.
"""
function convertint64(a::UInt8,b::UInt8,c::UInt8,d::UInt8,e::UInt8,f::UInt8,g::UInt8,h::UInt8)
    (UInt64(a) << 56) | (UInt64(b) << 48) | 
    (UInt64(c) << 40) | (UInt64(d) << 32) | 
    (UInt64(e) << 24) | (UInt64(f) << 16) | 
    (UInt64(g) << 8)  |  UInt64(h)
end

# TODO cannot use AbstractString for some reasons
"""
Concatenate an array of strings to a single string
"""
concatenate(strArray::Vector{T} where T <: AbstractString, separator=",") = 
    foldl((x, y) -> *(x, y, separator), "", strArray)[1:end-length(separator)]

"""
Convert a dictionary to an array of k=>v strings 
"""
stringarray(dict::Dict) = 
    ["$x => $y" for (x, y) in dict]

