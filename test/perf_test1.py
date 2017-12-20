from time import time
from pandas import read_sas
import sys

def perf_test(file):
    df = read_sas(file)

def benchmark(f, n):
    total = 0
    for i in range(n):
        t1 = time()
        f()
        t2 = time()
        elapsed = t2 - t1
        print("{:d}: elapsed {:f} seconds".format(i+1, elapsed))
        total += elapsed
    print("Average: {:.4f} seconds".format(total/n))

def run():
    perf_test(sys.argv[1])

if len(sys.argv) != 2:
    sys.exit("Usage: %s filename" % sys.argv[0])
benchmark(run, 10)
