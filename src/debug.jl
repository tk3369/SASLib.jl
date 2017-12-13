# debug facility
enable_debug = false

function setdebug(on::Bool) 
    global enable_debug
    enable_debug = on
end

macro debug(msg)
    return :( 
        global enable_debug; 
        if enable_debug::Bool
            println($msg)
        end 
    )
end

