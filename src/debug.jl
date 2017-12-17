# debug facility
const enable_debug = true

macro debug(msg)
    return :( 
        global enable_debug; 
        if enable_debug::Bool
            println($msg)
        end 
    )
end
