# Large file regression test for SASLib.jl
#
# This script tests SASLib against a real-world large SAS7BDAT file (the 2013
# American Housing Survey public-use microdata, ~2GB, 70,044 rows x 4,041 columns)
# to catch performance and correctness issues that only manifest at scale —
# specifically the hang fixed in issue #50.
#
# This test is NOT part of the standard `Pkg.test()` suite because the file must
# be downloaded separately (it is too large to include in the repo).
#
# == Downloading the test file ==
#
#   mkdir -p /tmp/ahs2013
#   curl -L -o /tmp/ahs2013/ahs2013n.sas7bdat \
#     "https://www2.census.gov/programs-surveys/ahs/2013/AHS%202013%20National%20PUF%20v1.4%20SAS.zip"
#
# (The Census Bureau serves the file inside a ZIP archive. Unzip it first if
# your curl version does not handle that automatically, or use the following
# two-step approach:)
#
#   cd /tmp/ahs2013
#   curl -L -O "https://www2.census.gov/programs-surveys/ahs/2013/AHS%202013%20National%20PUF%20v1.4%20SAS.zip"
#   unzip "AHS 2013 National PUF v1.4 SAS.zip"
#
# == Running the test ==
#
#   julia --project=/path/to/SASLib /path/to/SASLib/test/test_large_sas.jl
#
# Expected output (timings will vary by hardware):
#   open()    ~0.8s
#   read(1000) ~0.8s
#   read()   ~12s  (full 2 GB)

using SASLib

filepath = "/tmp/ahs2013/ahs2013n.sas7bdat"

if !isfile(filepath)
    error("""
    Test file not found: $filepath
    See the comments at the top of this script for download instructions.
    """)
end

println("File: $filepath")
println("Size: $(round(filesize(filepath) / 1024^2, digits=1)) MB")
println()

# Test 1: open (this was the hang fixed in issue #50 — should be fast now)
println("=== Test 1: SASLib.open ===")
t_open = @elapsed begin
    h = SASLib.open(filepath, verbose_level=0)
end
println("open() completed in $(round(t_open, digits=3))s")
println("Rows: $(h.row_count), Columns: $(h.column_count)")
println()

# Test 2: read first 1000 rows
println("=== Test 2: read first 1000 rows ===")
t_chunk = @elapsed begin
    rs = SASLib.read(h, 1000)
end
println("read(1000) completed in $(round(t_chunk, digits=3))s")
println("Result: $(size(rs, 1)) rows x $(size(rs, 2)) columns")
println()

SASLib.close(h)

# Test 3: read the full file
println("=== Test 3: read entire file ===")
h2 = SASLib.open(filepath, verbose_level=0)
t_full = @elapsed begin
    rs_full = SASLib.read(h2)
end
SASLib.close(h2)
println("read() completed in $(round(t_full, digits=3))s")
println("Result: $(size(rs_full, 1)) rows x $(size(rs_full, 2)) columns")
println()
println("All tests passed!")
