using SASLib, PooledArrays, BenchmarkTools

versioninfo()

opfn(size) = SASLib.ObjectPool{String}{UInt32}("", size)
pafn(size) = PooledArray{String,UInt32}(fill("", size))
rafn(size) = fill("", size)

size = 100000
dishes = ["food$i" for i in 1:size]

assignitems = (x::AbstractArray, y::AbstractArray) -> x[1:end] = y[1:end]
nsamples = 5000
nseconds = 600

println("** Regular Array **")
bra = @benchmarkable assignitems(x, y) setup=((x,y)=($rafn($size), $dishes)) samples=nsamples seconds=nseconds
display(run(bra))

println("\n\n** Pooled Array (Dict Pool) **")
bpa = @benchmarkable assignitems(x, y) setup=((x,y)=($pafn($size), $dishes)) samples=nsamples seconds=nseconds
display(run(bpa))

println("\n\n** Object Pool **")
bop = @benchmarkable assignitems(x, y) setup=((x,y)=($opfn($size), $dishes)) samples=nsamples seconds=nseconds
display(run(bop))

println()
println()
