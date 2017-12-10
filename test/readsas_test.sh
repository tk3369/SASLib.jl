julia <<EOF
using SASLib
SASLib.debugon()
df = SASLib.readsas("$1")
println(size(df))
EOF
