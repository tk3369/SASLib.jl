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
Print a subtype tree from the specified `roottype`
"""
function subtypetree(roottype, level=1, indent=4)
    level == 1 && println(roottype)
    for s in subtypes(roottype)
      println(join(fill(" ", level * indent)) * string(s))
      subtypetree(s, level+1, indent)
    end
end
