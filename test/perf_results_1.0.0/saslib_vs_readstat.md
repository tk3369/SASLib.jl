# SASLib vs ReadStat test

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
data_misc/numeric_1000000_2.sas7bdat    :  367.403 ms  164.249 ms ( 45%)  165.407 ms ( 45%)    2    0    0 none
data_misc/types.sas7bdat                :    0.067 ms    0.132 ms (196%)    0.132 ms (196%)    5    1    0 none
data_AHS2013/homimp.sas7bdat            :   54.358 ms   39.673 ms ( 73%)   21.815 ms ( 40%)    1    5    0 none
data_AHS2013/omov.sas7bdat              :    3.644 ms    6.631 ms (182%)    5.451 ms (150%)    3    5    0 none
data_AHS2013/owner.sas7bdat             :   18.117 ms   13.985 ms ( 77%)    8.112 ms ( 45%)    0    3    0 none
data_AHS2013/ratiov.sas7bdat            :    6.723 ms    6.038 ms ( 90%)    3.197 ms ( 48%)    0    9    0 none
data_AHS2013/rmov.sas7bdat              :   72.551 ms   90.487 ms (125%)   63.868 ms ( 88%)    2   21    0 none
data_AHS2013/topical.sas7bdat           : 3394.267 ms 1755.026 ms ( 52%) 1153.360 ms ( 34%)    8  106    0 none
data_pandas/airline.sas7bdat            :    0.093 ms    0.114 ms (122%)    0.117 ms (125%)    6    0    0 none
data_pandas/datetime.sas7bdat           :    0.061 ms    0.133 ms (219%)    0.132 ms (217%)    1    1    2 none
data_pandas/productsales.sas7bdat       :    2.812 ms    1.726 ms ( 61%)    1.075 ms ( 38%)    4    5    1 none
data_pandas/test1.sas7bdat              :    0.606 ms    0.900 ms (148%)    0.836 ms (138%)   73   25    2 none
data_pandas/test2.sas7bdat              :    0.624 ms    0.693 ms (111%)    0.690 ms (111%)   73   25    2  RLE
data_pandas/test4.sas7bdat              :    0.607 ms    0.885 ms (146%)    0.849 ms (140%)   73   25    2 none
data_pandas/test5.sas7bdat              :    0.625 ms    0.721 ms (115%)    0.693 ms (111%)   73   25    2  RLE
data_pandas/test7.sas7bdat              :    0.606 ms    0.912 ms (151%)    0.855 ms (141%)   73   25    2 none
data_pandas/test9.sas7bdat              :    0.622 ms    0.701 ms (113%)    0.705 ms (113%)   73   25    2  RLE
data_pandas/test10.sas7bdat             :    0.606 ms    0.955 ms (158%)    0.844 ms (139%)   73   25    2 none
data_pandas/test12.sas7bdat             :    0.625 ms    0.702 ms (112%)    0.683 ms (109%)   73   25    2  RLE
data_pandas/test13.sas7bdat             :    0.606 ms    0.924 ms (152%)    0.860 ms (142%)   73   25    2 none
data_pandas/test15.sas7bdat             :    0.623 ms    0.725 ms (116%)    0.698 ms (112%)   73   25    2  RLE
data_pandas/test16.sas7bdat             :    0.614 ms    1.572 ms (256%)    1.626 ms (265%)   73   25    2 none
data_reikoch/barrows.sas7bdat           :   11.242 ms    6.438 ms ( 57%)    6.513 ms ( 58%)   72    0    0  RLE
data_reikoch/extr.sas7bdat              :    0.077 ms    0.310 ms (400%)    0.303 ms (391%)    0    1    0 none
data_reikoch/ietest2.sas7bdat           :    0.048 ms    0.106 ms (221%)    0.106 ms (221%)    0    1    0  RLE
```
