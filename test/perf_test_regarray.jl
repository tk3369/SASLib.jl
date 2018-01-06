using BenchmarkTools

if length(ARGS) != 2
    println("Usage: $PROGRAM_FILE <filename> <count>")
	exit()
end

versioninfo()
println()

tic()
using SASLib
@printf "Loaded library in %.3f seconds\n" toq()

b = @benchmark readsas($ARGS[1], verbose_level=0, string_array_fn=Dict(:_all_ => REGULAR_STR_ARRAY)) samples=parse(Int, ARGS[2])
display(b)

println()
println()
