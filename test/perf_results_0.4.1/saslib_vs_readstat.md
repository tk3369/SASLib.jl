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
data_misc/numeric_1000000_2.sas7bdat    :  205.002 ms  152.764 ms ( 75%)  154.288 ms ( 75%)    2    0    0 None
data_misc/types.sas7bdat                :    0.093 ms    0.179 ms (194%)    0.180 ms (194%)    5    1    0 None
data_AHS2013/homimp.sas7bdat            :   40.138 ms   51.994 ms (130%)   24.975 ms ( 62%)    1    5    0 None
data_AHS2013/omov.sas7bdat              :    2.557 ms    5.136 ms (201%)    3.485 ms (136%)    3    5    0  RLE
data_AHS2013/owner.sas7bdat             :   13.859 ms   17.104 ms (123%)    9.272 ms ( 67%)    0    3    0 None
data_AHS2013/ratiov.sas7bdat            :    4.820 ms    8.170 ms (169%)    3.577 ms ( 74%)    0    9    0 None
data_AHS2013/rmov.sas7bdat              :   56.358 ms  101.530 ms (180%)   70.293 ms (125%)    2   21    0  RLE
data_AHS2013/topical.sas7bdat           : 2609.437 ms 2876.122 ms (110%) 1104.849 ms ( 42%)    8  106    0  RLE
data_pandas/airline.sas7bdat            :    0.105 ms    0.170 ms (161%)    0.172 ms (164%)    6    0    0 None
data_pandas/datetime.sas7bdat           :    0.080 ms    0.235 ms (293%)    0.234 ms (291%)    1    1    2 None
data_pandas/productsales.sas7bdat       :    2.276 ms    2.374 ms (104%)    1.355 ms ( 60%)    4    5    1 None
data_pandas/test1.sas7bdat              :    0.831 ms    1.162 ms (140%)    1.101 ms (132%)   73   25    2 None
data_pandas/test2.sas7bdat              :    0.846 ms    1.029 ms (122%)    0.971 ms (115%)   73   25    2  RLE
data_pandas/test4.sas7bdat              :    0.829 ms    1.162 ms (140%)    1.103 ms (133%)   73   25    2 None
data_pandas/test5.sas7bdat              :    0.848 ms    1.034 ms (122%)    0.974 ms (115%)   73   25    2  RLE
data_pandas/test7.sas7bdat              :    0.832 ms    1.182 ms (142%)    1.111 ms (133%)   73   25    2 None
data_pandas/test9.sas7bdat              :    0.850 ms    1.057 ms (124%)    0.993 ms (117%)   73   25    2  RLE
data_pandas/test10.sas7bdat             :    0.833 ms    1.166 ms (140%)    1.102 ms (132%)   73   25    2 None
data_pandas/test12.sas7bdat             :    0.849 ms    1.038 ms (122%)    0.974 ms (115%)   73   25    2  RLE
data_pandas/test13.sas7bdat             :    0.831 ms    1.180 ms (142%)    1.110 ms (134%)   73   25    2 None
data_pandas/test15.sas7bdat             :    0.852 ms    1.048 ms (123%)    0.988 ms (116%)   73   25    2  RLE
data_pandas/test16.sas7bdat             :    0.842 ms    2.236 ms (265%)    2.152 ms (255%)   73   25    2 None
data_reikoch/barrows.sas7bdat           :    6.923 ms    6.031 ms ( 87%)    6.047 ms ( 87%)   72    0    0  RLE
data_reikoch/extr.sas7bdat              :    0.177 ms    0.381 ms (215%)    0.368 ms (208%)    0    1    0 None
data_reikoch/ietest2.sas7bdat           :    0.061 ms    0.139 ms (229%)    0.138 ms (228%)    0    1    0  RLE
```
