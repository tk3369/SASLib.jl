from time import time
from pandas import read_sas

def perf_test1():
    df = read_sas("numeric_1000000_2.sas7bdat")

def benchmark(f, n):
    total = 0
    for i in range(n):
        t1 = time()
        f()
        t2 = time()
        elapsed = t2 - t1
        print("{:d}: elapsed {:f} seconds".format(i+1, elapsed))
        total += elapsed

    print("Average: {:f} seconds".format(int(total/n)))

benchmark(perf_test1, 10)
