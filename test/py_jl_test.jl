# Compare loading one file in Python vs Julia

if length(ARGS) != 3
    println("Usage: $PROGRAM_FILE <filename> <count> <outputdir>")
	exit()
end

using SASLib, BenchmarkTools, Humanize

file = ARGS[1]
cnt = ARGS[2]
dir = ARGS[3]
basename = split(file, "/")[end]
shortname = replace(basename, r"\.sas7bdat", "")
output = "$dir/py_jl_$(shortname)_$(cnt).md"

prt(msg...) = info(now(), " ", msg...)

# run python part
# result is minimum time in seconds
prt("Running python test for file ", file, " ", cnt, " times")
pyver_cmd = `python -V`
pyres_cmd = `python perf_test1.py $file $cnt`
pyver = readstring(pipeline(pyver_cmd, stderr=pipeline(`cat`)))
pyres = readstring(pipeline(pyres_cmd))
py = parse(Float64, match(r"[0-9]*\.[0-9]*", pyres).match) 

# read metadata
prt("Reading metadata of data file")
meta = metadata(file)
nrows = meta.nrows
ncols = meta.ncols
nnumcols = count(x -> x == Float64, [ty for (name, ty) in meta.columnsinfo])
nstrcols = ncols - nnumcols

# run julia part
prt("Running julia test")
jlb1 = @benchmark readsas(file, verbose_level=0) samples=parse(Int, cnt)
jl1 = jlb1.times[1] / 1e9   # convert nanoseconds to seconds

# run julia part using regular string array
if nstrcols > 0
    prt("Running julia test (regular string array)")
    jlb2 = @benchmark readsas(file, string_array_fn=Dict(:_all_=>REGULAR_STR_ARRAY), 
        verbose_level=0) samples=parse(Int, cnt)
    jl2 = jlb2.times[1] / 1e9   # convert nanoseconds to seconds
    jl = min(jl1, jl2)    # pick faster run
    jltitle = "Julia (ObjectPool)"
else
    jl = jl1
    jltitle = "Julia"
end

# analysis
direction = jl < py ? "faster" : "slower"
ratio = round(direction == "faster" ? py/jl : jl/py, 1)

io = nothing
try
    io = open(output, "w")
    println(io, "# Julia/Python Performance Test Result")
    println(io)
    println(io, "## Summary")
    println(io)
    println(io, "Julia is ~$(ratio)x $direction than Python/Pandas")
    println(io)
    println(io, "## Test File")
    println(io)
    println(io, "Iterations: $cnt")
    println(io)
    println(io, "Filename|Size|Rows|Columns|Numeric Columns|String Columns")
    println(io, "--------|----|----|-------|---------------|--------------")
    println(io, "$basename|$(datasize(lstat(file).size))|$nrows|$ncols|$nnumcols|$nstrcols")
    println(io, "")
    println(io, "## Python")
    println(io, "```")
    println(io, "\$ $(join(pyver_cmd.exec, " "))")
    println(io, pyver)
    println(io, "\$ $(join(pyres_cmd.exec, " "))")
    println(io, pyres)
    println(io, "```")
    println(io)
    println(io, "## $jltitle")
    println(io, "```")
    versioninfo(io)
    println(io)
    show(io, MIME"text/plain"(), jlb1)
    println(io, "\n```")
    if nstrcols > 0
        println(io)
        println(io, "## Julia (Regular String Array)")
        println(io, "```")
        versioninfo(io)
        println(io)
        show(io, MIME"text/plain"(), jlb2)
        println(io, "\n```")
    end
catch err
     println(err)
finally
    io != nothing && try close(io) catch e println(e) end
end
prt("Written file $output")
