# Regression test script for SASLib.
#
# Usage:
#   julia test/regression.jl save [output_file]
#       Generate SHA256 digests for all test SAS files and save to output_file.
#       Default output_file: regression_baseline.txt
#
#   julia test/regression.jl compare <baseline_file> [current_file]
#       Compare digests. If current_file is omitted, generates fresh digests
#       in memory and compares against baseline_file.
#       Exit code 0 = all match, 1 = differences found.
#
# Typical workflow:
#   # Before making changes (on parent commit):
#   julia test/regression.jl save regression_baseline.txt
#
#   # After making changes:
#   julia test/regression.jl compare regression_baseline.txt

cd(@__DIR__)

import Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using SASLib
using SHA
using Dates

const TEST_DIRS = ["data_pandas", "data_reikoch", "data_AHS2013", "data_misc", "data_big5", "data_objectpool"]
const SKIP_FILES = Set(["zero_variables.sas7bdat"])
const DEFAULT_DIGEST_FILE = "regression_baseline.txt"

function all_test_files()
    files = String[]
    for dir in TEST_DIRS
        isdir(dir) || continue
        for f in sort(readdir(dir))
            endswith(f, ".sas7bdat") && f ∉ SKIP_FILES && push!(files, joinpath(dir, f))
        end
    end
    files
end

# --- Digest computation ---

function compute_digest(filepath::String)
    rs = readsas(filepath; verbose_level=0)
    ctx = SHA2_256_CTX()
    SHA.update!(ctx, reinterpret(UInt8, [Int64(size(rs, 1)), Int64(size(rs, 2))]))
    for nm in names(rs)
        SHA.update!(ctx, codeunits(String(nm)))
        SHA.update!(ctx, UInt8[0x00])
    end
    for (nm, col) in zip(names(rs), columns(rs))
        SHA.update!(ctx, codeunits(String(nm)))
        SHA.update!(ctx, UInt8[0x00])
        update_column!(ctx, col)
    end
    bytes2hex(SHA.digest!(ctx))
end

function update_column!(ctx, col::Vector{Float64})
    SHA.update!(ctx, reinterpret(UInt8, col))
end

function update_column!(ctx, col::AbstractVector{String})
    for v in col
        SHA.update!(ctx, codeunits(v))
        SHA.update!(ctx, UInt8[0x00])
    end
end

function update_column!(ctx, col::AbstractVector{Union{String, Missing}})
    for v in col
        if ismissing(v)
            SHA.update!(ctx, UInt8[0xFF])
        else
            SHA.update!(ctx, codeunits(v))
            SHA.update!(ctx, UInt8[0x00])
        end
    end
end

function update_column!(ctx, col::AbstractVector{Union{Date, Missing}})
    for v in col
        val = ismissing(v) ? typemin(Int64) : Int64(Dates.value(v))
        SHA.update!(ctx, reinterpret(UInt8, [val]))
    end
end

function update_column!(ctx, col::AbstractVector{Union{DateTime, Missing}})
    for v in col
        val = ismissing(v) ? typemin(Int64) : Int64(Dates.value(v))
        SHA.update!(ctx, reinterpret(UInt8, [val]))
    end
end

function update_column!(ctx, col::AbstractVector)
    for v in col
        SHA.update!(ctx, codeunits(repr(v)))
        SHA.update!(ctx, UInt8[0x00])
    end
end

# --- I/O helpers ---

function generate_digests()
    files = all_test_files()
    results = Dict{String, String}()
    skipped = Dict{String, String}()
    for filepath in files
        try
            digest = compute_digest(filepath)
            results[filepath] = digest
            println("  OK    $filepath")
        catch e
            msg = sprint(showerror, e)
            skipped[filepath] = msg
            println("  SKIP  $filepath  ($msg)")
        end
    end
    results, skipped
end

function save_digests(output_file::String)
    println("Generating digests for all test files...")
    results, skipped = generate_digests()
    open(output_file, "w") do io
        println(io, "# SASLib Regression Digest")
        println(io, "# Generated: $(now())")
        for (filepath, digest) in sort(collect(results))
            println(io, "$filepath\t$digest")
        end
        for (filepath, msg) in sort(collect(skipped))
            println(io, "# SKIP: $filepath ($msg)")
        end
    end
    println("\nSaved $(length(results)) digests to $output_file")
    return 0
end

function load_digests(filename::String)
    digests = Dict{String, String}()
    open(filename) do io
        for line in eachline(io)
            startswith(line, "#") && continue
            isempty(strip(line)) && continue
            parts = split(line, "\t")
            length(parts) == 2 || continue
            digests[String(parts[1])] = String(parts[2])
        end
    end
    digests
end

function compare_digests(baseline_file::String, current_file::Union{String, Nothing})
    println("Loading baseline from $baseline_file...")
    baseline = load_digests(baseline_file)

    current = if current_file === nothing
        println("Generating current digests...")
        results, _ = generate_digests()
        results
    else
        println("Loading current from $current_file...")
        load_digests(current_file)
    end

    println("\n=== Regression Report ===")

    all_files = sort(collect(union(keys(baseline), keys(current))))
    matches = 0
    diffs   = String[]
    added   = String[]
    removed = String[]

    for f in all_files
        in_baseline = haskey(baseline, f)
        in_current  = haskey(current, f)
        if in_baseline && in_current
            baseline[f] == current[f] ? (matches += 1) : push!(diffs, f)
        elseif in_current
            push!(added, f)
        else
            push!(removed, f)
        end
    end

    total = length(all_files)
    println("$matches / $total files match")

    if !isempty(diffs)
        println("\nDIFFERENCES ($(length(diffs)) files):")
        for f in diffs
            println("  DIFF  $f")
            println("        baseline: $(baseline[f])")
            println("        current:  $(current[f])")
        end
    end

    !isempty(added)   && (println("\nNEW FILES ($(length(added))):");   foreach(f -> println("  NEW   $f"), added))
    !isempty(removed) && (println("\nREMOVED FILES ($(length(removed))):");foreach(f -> println("  GONE  $f"), removed))

    if isempty(diffs) && isempty(added) && isempty(removed)
        println("All files match. No regressions detected.")
        return 0
    end
    return 1
end

# --- Entry point ---

function main()
    if length(ARGS) < 1
        println("""
        Usage:
          julia regression.jl save [output_file]
              Generate digests for all test SAS files and save to output_file.
              Default: $DEFAULT_DIGEST_FILE

          julia regression.jl compare <baseline_file> [current_file]
              Compare digests. If current_file is omitted, generates fresh digests
              and compares against baseline_file.
              Exit code: 0 = all match, 1 = differences found
        """)
        return 1
    end

    mode = ARGS[1]

    if mode == "save"
        output = length(ARGS) >= 2 ? ARGS[2] : DEFAULT_DIGEST_FILE
        return save_digests(output)
    elseif mode == "compare"
        if length(ARGS) < 2
            println("Error: 'compare' requires a baseline file.")
            return 1
        end
        baseline = ARGS[2]
        current  = length(ARGS) >= 3 ? ARGS[3] : nothing
        return compare_digests(baseline, current)
    else
        println("Unknown mode: '$mode'. Use 'save' or 'compare'.")
        return 1
    end
end

exit(main())
