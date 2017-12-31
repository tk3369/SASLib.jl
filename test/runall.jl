using SASLib

files = filter(x -> endswith(x, "sas7bdat"), Base.Filesystem.readdir())
for f in files
    println("=== $f ===")
    result = readsas(f)
end
