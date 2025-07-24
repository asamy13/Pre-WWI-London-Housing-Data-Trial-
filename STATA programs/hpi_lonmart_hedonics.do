/* Program: HPI London Auction Data */

#delimit ;
clear;
eststo clear;

insheet using "...\lonmart_wcensus.csv";

drop if year < 1895 | year > 1914;
drop if value < 100 | value > 1000;
drop if years_purchase < 2.8 | years_purchase > 30;



*Variables;
gen lvalue = log(value);
tabstat value, by(year) statistics(mean median sd);
tabstat value if year==1900, by(london_region) statistics(mean median sd);


*Hedonics Regressions;

*Annual HPIs;
sort year;
by year: sum value;
char tenure_type[omit] "FREEHOLD";
constraint 1 leasehold_unexpired_term = 0;
constraint 2 _ItenXlease_2 = 0;

*Full Model;
forvalues x=1895/1914 {;
	eststo: xi: reg lvalue i.borough rent_yearly_inpounds (i.tenure_type)##(c.leasehold_unexpired_term) n_hhs n_rooms persons_rooms camsis d_servants if year==`x';
	predict p`x', xb;
	gen pp`x' = exp(p`x');
	estimates store m`x';
};
esttab using "C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\londonmart_hpi_regcoeffs_imputed.rtf", plain not scalars(r2) replace;
outsheet lonmart_id year value quarter lvalue p1895 p1896 p1897 p1898 p1899 p1900 p1901 p1902 p1903 p1904 p1905 p1906 p1907 p1908 p1909 p1910 p1911 p1912 p1913 p1914 pp1895 pp1896 pp1897 pp1898 pp1899 pp1900 pp1901 pp1902 pp1903 pp1904 pp1905 pp1906 pp1907 pp1908 pp1909 pp1910 pp1911 pp1912 pp1913 pp1914 
		 using "C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\hpi_lonmart_imputed.csv", comma replace;
