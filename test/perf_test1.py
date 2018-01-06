from time import time
from pandas import read_sas
import numpy as np
import sys

def perf_test(file):
    df = read_sas(file)

def benchmark(f, n):
    values = []
    for i in range(n):
        t1 = time()
        f()
        t2 = time()
        elapsed = t2 - t1
        # print("{:d}: elapsed {:f} seconds".format(i+1, elapsed))
        values.append(elapsed)
    print("Minimum: {:.4f} seconds".format(np.min(values)))
    print("Median:  {:.4f} seconds".format(np.median(values)))
    print("Mean:    {:.4f} seconds".format(np.mean(values)))
    print("Maximum: {:.4f} seconds".format(np.max(values)))

def run():
    perf_test(sys.argv[1])

if len(sys.argv) != 3:
    sys.exit("Usage: %s <filename> <count>" % sys.argv[0])

benchmark(run, int(sys.argv[2]))
