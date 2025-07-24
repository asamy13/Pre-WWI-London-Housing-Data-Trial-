#delimit;
clear;
set more off;
eststo clear;

insheet using "C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Data\lonmart_repeatsales_1895_1914.csv";

*house prices;
eststo: reg lprice_diff d_1896 d_1897 d_1898 d_1899 d_1900 d_1901 d_1902 d_1903 d_1904 d_1905 d_1906 d_1907 d_1908 d_1909 d_1910 d_1911 d_1912 d_1913 d_1914, noconstant;
*total rent prices;
eststo: reg lrents_diff d_1896 d_1897 d_1898 d_1899 d_1900 d_1901 d_1902 d_1903 d_1904 d_1905 d_1906 d_1907 d_1908 d_1909 d_1910 d_1911 d_1912 d_1913 d_1914 , noconstant;
*ground rents;
eststo: reg lgroundrents_diff d_1896 d_1897 d_1898 d_1899 d_1900 d_1901 d_1902 d_1903 d_1904 d_1905 d_1906 d_1907 d_1908 d_1909 d_1910 d_1911 d_1912 d_1913 d_1914 , noconstant;

esttab using "C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\londonmart_allindices_regcoeffs_repeatsales.rtf", plain not scalars(r2) replace;

esttab using "C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\londonmart_allindices_regcoeffs_repeatsales.csv", plain not scalars(r2) replace;