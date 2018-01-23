## SASLib vs ReadStat results

Key     | Description |
--------|-------------------------|
F64     | number of Float64 columns|
STR     | number of String columns|
DT      | number of date/time coumns|
COMP    | compression method|
S/R     | SASLib time divided by ReadStat time|
SA/R    | SASLib time (regular string arrays) divided by ReadStat time|
SASLibA | SASLib (regular string arrays)|


```
Filename                                : ReadStat      SASLib    S/R     SASLibA    SA/R    F64  STR   DT COMP
data_AHS2013/homimp.sas7bdat            :   39.610 ms   46.910 ms (118%)   25.087 ms ( 63%)    1    5    0 None
data_AHS2013/omov.sas7bdat              :    2.590 ms    4.736 ms (183%)    3.485 ms (135%)    3    5    0  RLE
data_AHS2013/owner.sas7bdat             :   13.884 ms   15.026 ms (108%)    9.513 ms ( 69%)    0    3    0 None
data_AHS2013/ratiov.sas7bdat            :    4.853 ms    6.950 ms (143%)    3.715 ms ( 77%)    0    9    0 None
data_AHS2013/rmov.sas7bdat              :   57.023 ms   84.570 ms (148%)   63.294 ms (111%)    2   21    0  RLE
data_AHS2013/topical.sas7bdat           : 2175.098 ms 2433.403 ms (112%) 1123.849 ms ( 52%)    8  106    0  RLE
data_misc/numeric_1000000_2.sas7bdat    :  222.189 ms  154.134 ms ( 69%)  157.427 ms ( 71%)    2    0    0 None
data_misc/types.sas7bdat                :    0.094 ms    0.184 ms (196%)    0.183 ms (196%)    5    1    0 None
data_pandas/airline.sas7bdat            :    0.108 ms    0.177 ms (164%)    0.181 ms (167%)    6    0    0 None
data_pandas/datetime.sas7bdat           :    0.082 ms    0.243 ms (295%)    0.243 ms (295%)    1    1    2 None
data_pandas/productsales.sas7bdat       :    2.305 ms    2.119 ms ( 92%)    1.360 ms ( 59%)    4    5    1 None
data_pandas/test1.sas7bdat              :    0.841 ms    1.167 ms (139%)    1.113 ms (132%)   73   25    2 None
data_pandas/test10.sas7bdat             :    0.843 ms    1.173 ms (139%)    1.117 ms (132%)   73   25    2 None
data_pandas/test12.sas7bdat             :    0.860 ms    1.047 ms (122%)    0.990 ms (115%)   73   25    2  RLE
data_pandas/test13.sas7bdat             :    0.845 ms    1.189 ms (141%)    1.132 ms (134%)   73   25    2 None
data_pandas/test15.sas7bdat             :    0.862 ms    1.058 ms (123%)    1.006 ms (117%)   73   25    2  RLE
data_pandas/test16.sas7bdat             :    0.854 ms    2.329 ms (273%)    2.295 ms (269%)   73   25    2 None
data_pandas/test2.sas7bdat              :    0.860 ms    1.042 ms (121%)    0.990 ms (115%)   73   25    2  RLE
data_pandas/test4.sas7bdat              :    0.842 ms    1.171 ms (139%)    1.113 ms (132%)   73   25    2 None
data_pandas/test5.sas7bdat              :    0.861 ms    1.034 ms (120%)    0.982 ms (114%)   73   25    2  RLE
data_pandas/test7.sas7bdat              :    0.843 ms    1.185 ms (141%)    1.125 ms (133%)   73   25    2 None
data_pandas/test9.sas7bdat              :    0.858 ms    1.063 ms (124%)    1.006 ms (117%)   73   25    2  RLE
data_reikoch/barrows.sas7bdat           :    7.449 ms    6.059 ms ( 81%)    6.063 ms ( 81%)   72    0    0  RLE
data_reikoch/extr.sas7bdat              :    0.178 ms    0.388 ms (218%)    0.382 ms (215%)    0    1    0 None
data_reikoch/ietest2.sas7bdat           :    0.061 ms    0.142 ms (231%)    0.141 ms (230%)    0    1    0  RLE
```
