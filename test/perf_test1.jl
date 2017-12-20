
if length(ARGS) != 1
    println("Usage: $PROGRAM_FILE filename")
	exit()
end

tic()
using SASLib
@printf "Loaded library in %.3f seconds\n" toq()

function perf(f, n) 
    # bootstrap first call so the function is compiled
    tic()
    f()
    @printf "Bootstrap elapsed %.3f seconds\n" toq()
    
    total = 0
    for i in 1:n
        tic()
        f()
				elapsed = toq()
        total += elapsed
        @printf "Elapsed %.3f seconds\n" elapsed
    end
    println("Average: $(total / n) seconds")
end

perf(() -> readsas(ARGS[1], Dict(:verbose_level => 0)), 10)
