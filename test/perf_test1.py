from time import time
from pandas import read_sas

def perf_test1():
    df = read_sas("test1.sas7bdat")

def benchmark(f, n):
    total = 0
    for i in range(n):
        t1 = time()
        f()
        t2 = time()
        elapsed = t2 - t1
        print("{:d}: elapsed {:f} seconds".format(i, elapsed))
        total += elapsed

    print("Average: {:d} msec".format(int(total/n*1000)))

benchmark(perf_test1, 10)
