using SASLib

function perf(f, n) 
    # bootstrap first call so the function is compiled
    f()

    total = 0
    for i in 1:n
        t1 = time()
        f()
        t2 = time()
        elapsed = t2 - t1
        println("$i: elapsed $elapsed seconds")
        total += elapsed
    end
    println("Average: $(total / n * 1000) msec")
end

perf(() -> readsas("test1.sas7bdat"), 10)
