```
Julia Version 0.6.2
Commit d386e40c17 (2017-12-13 18:08 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin14.5.0)
  CPU: Intel(R) Core(TM) i5-4258U CPU @ 2.40GHz
  WORD_SIZE: 64
  BLAS: libopenblas (USE64BITINT DYNAMIC_ARCH NO_AFFINITY Haswell)
  LAPACK: libopenblas64_
  LIBM: libopenlibm
  LLVM: libLLVM-3.9.1 (ORCJIT, haswell)
** Regular Array **
BenchmarkTools.Trial: 
  memory estimate:  781.33 KiB
  allocs estimate:  2
  --------------
  minimum time:     170.532 μs (0.00% GC)
  median time:      368.824 μs (0.00% GC)
  mean time:        630.629 μs (21.69% GC)
  maximum time:     23.323 ms (0.00% GC)
  --------------
  samples:          5000
  evals/sample:     1

** Pooled Array (Dict Pool) **
BenchmarkTools.Trial: 
  memory estimate:  9.43 MiB
  allocs estimate:  65
  --------------
  minimum time:     35.474 ms (0.00% GC)
  median time:      42.527 ms (0.00% GC)
  mean time:        43.822 ms (5.10% GC)
  maximum time:     110.314 ms (0.00% GC)
  --------------
  samples:          5000
  evals/sample:     1

** Object Pool **
BenchmarkTools.Trial: 
  memory estimate:  7.10 MiB
  allocs estimate:  51
  --------------
  minimum time:     28.510 ms (0.00% GC)
  median time:      34.356 ms (0.00% GC)
  mean time:        35.081 ms (3.44% GC)
  maximum time:     80.241 ms (0.00% GC)
  --------------
  samples:          5000
  evals/sample:     1
```