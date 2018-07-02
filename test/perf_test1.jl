using BenchmarkTools
using InteractiveUtils
using Printf

if length(ARGS) != 2
    println("Usage: $PROGRAM_FILE <filename> <count>")
	exit()
end

versioninfo()
println()

load_time = @elapsed using SASLib
@printf "Loaded library in %.3f seconds\n" load_time

b = @benchmark readsas($ARGS[1], verbose_level=0) samples=parse(Int, ARGS[2])
display(b)

println()
println()
