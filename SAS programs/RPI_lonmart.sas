/* Program: rpi - LondonMart - Computing Double-Imputation Fisher rpis
NOTE: This program requires predicted values from Hedonics models estimated in:
C:\Users\Luke Samy\Documents\Postdoctoral\Research Projects\rpi\STATA programs and output\rpi_london_auction_imputation.do 
*/

%let start_year=1895;
%let end_year=1914;
%let baseyear=1895;

proc import datafile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\rpi_lonmart_imputed.csv"
			out=lonmart_data
			replace;
run;

proc contents data=lonmart_data;
run;

*Create Laspeyres Indices;
%macro create_Laspeyres_rpi(start=, end=);
proc means data=lonmart_data;
	var %do i=&start %to &end; pp&i %end;;
	where year=&baseyear;
	output out=sum_pps sum=%do i=&start %to &end; sumpp&i %end;;
run;

data temp;
	set sum_pps;
	%do i=&start %to &end;
	rpi_&i = sumpp&i / sumpp&baseyear *100;
	%end;
	drop %do i=&start %to &end; sumpp&i %end;;
run;

proc transpose data=temp out=rpi_laspeyres;
	var %do i=&start %to &end; rpi_&i %end;;
run;

data rpi_laspeyres;
	set rpi_laspeyres;
	year = _n_;
	year = year + &start - 1;
	rename _name_ = year_string col1=rpi_laspeyres;
	label _name_=year_string;
run;
%mend;
%create_Laspeyres_rpi(start=&start_year, end=&end_year);

*Create Paasche Index;
%macro create_paasche_rpi(start=, end=);
%do j=&start %to &end;
proc means data=lonmart_data nway;
	var pp&baseyear;
	class year;
	output out=basesum_&baseyear sum=basesum&baseyear;
run;

proc means data=lonmart_data;
	var pp&j;
	where year=&j;
	output out=sum_pps_&j sum=sumpp;
run;
%end;

data sum_pps;
	set %do i=&start %to &end; sum_pps_&i %end;;
run;

data sum_pps;
	set sum_pps;
	year = _n_;
	year = year + &start - 1;
	drop _type_;
	rename _freq_ = freq_year;
run;

data rpi_paasche;
	merge basesum_&baseyear sum_pps;
	by year;
run;

data rpi_paasche;
	set rpi_paasche;
	rpi_paasche = sumpp / basesum&baseyear * 100;
run;
%mend;
%create_paasche_rpi(start=&start_year, end=&end_year);

data rpi_imputed_alltypes;
	merge rpi_laspeyres rpi_paasche;
	by year;
	keep year rpi_laspeyres rpi_paasche;
run;

data rpi_imputed_alltypes;
	set rpi_imputed_alltypes;
	rpi_fisher = (((rpi_laspeyres / 100) * (rpi_paasche / 100))**0.5)* 100;
run;

proc gplot data=rpi_imputed_alltypes;
	plot (rpi_laspeyres rpi_paasche rpi_fisher) * year / overlay;
	symbol i=join;
run;

****************;
*Chained Indices;
****************;
%macro create_chainedlaspeyres_indices(start=, end=);
*Laspeyres;
%do i=%eval(&start+1) %to &end;
	%let j = %eval(&i-1);
	proc means data=lonmart_data;
		var pp&j pp&i;
		where year=&j;
		output out=sumchained_&i sum=sum_&j sum_&i;

	data sumchained_&i;
		set sumchained_&i;
		rpi_unchained_laspeyres = sum_&i / sum_&j;
		rpi_unchained_laspeyres_&i = sum_&i / sum_&j;
		obs = _n_;
		keep obs rpi_unchained_laspeyres rpi_unchained_laspeyres_&i;
	run;
%end;

data rpi_laspeyres_onerow;
	merge %do i=%eval(&start+1) %to &end; sumchained_&i(drop=rpi_unchained_laspeyres) %end;;
	by obs;
run;

data rpi_unchained_laspeyres;
	set %do i=%eval(&start+1) %to &end; sumchained_&i(keep=rpi_unchained_laspeyres) %end;;
	year = _n_ + &start;
run;

proc transpose data=rpi_unchained_laspeyres out=temp;
	var rpi_unchained_laspeyres;
	id year;
run;

data temp;
	set temp;
	rpi_&baseyear = 1;
	rpi_%eval(&start+1) = _%eval(&start+1);
	%do j=%eval(&start+2) %to &end;
			rpi_&j = _&j * rpi_%eval(&j-1);
	%end;
	drop %do k=%eval(&start+1) %to &end; _&k %end;;
run;

proc transpose data=temp out=rpi_chained_laspeyres;
	var %do k=&start %to &end; rpi_&k %end;;
run;

data rpi_chained_laspeyres;
	set rpi_chained_laspeyres;
	rpi_chained_laspeyres = rpi_unchained_laspeyres * 100;
	year = _n_ + &start - 1;
run;
%mend;
%create_chainedlaspeyres_indices(start=&start_year, end=&end_year);


*Chained Indices;
%macro create_chainedpaasche_indices(start=, end=);
*paasche;
%do i=%eval(&start+1) %to &end;
	%let j = %eval(&i-1);
	proc means data=lonmart_data;
		var pp&j pp&i;
		where year=&i;
		output out=sumchained_&i sum=sum_&j sum_&i;
	run;

	data sumchained_&i;
		set sumchained_&i;
		rpi_unchained_paasche = sum_&i / sum_&j;
		rpi_unchained_paasche_&i = sum_&i / sum_&j;
		obs = _n_;
		keep obs rpi_unchained_paasche rpi_unchained_paasche_&i;
	run;
%end;

data rpi_paasche_onerow;
	merge %do i=%eval(&start+1) %to &end; sumchained_&i(drop=rpi_unchained_paasche) %end;;
	by obs;
run;

data rpi_unchained_paasche;
	set %do i=%eval(&start+1) %to &end; sumchained_&i(keep = rpi_unchained_paasche) %end;;
	year = _n_ + &start;
run;

proc transpose data=rpi_unchained_paasche out=temp;
	var rpi_unchained_paasche;
	id year;
run;

data temp;
	set temp;
	rpi_&baseyear = 1;
	rpi_%eval(&start+1) = _%eval(&start+1);
	%do j=%eval(&start+2) %to &end;
			rpi_&j = _&j * rpi_%eval(&j-1);
	%end;
	drop %do k=%eval(&start+1) %to &end; _&k %end;;
run;

proc transpose data=temp out=rpi_chained_paasche;
	var %do k=%eval(&start) %to &end; rpi_&k %end;;
run;

data rpi_chained_paasche;
	set rpi_chained_paasche;
	rpi_chained_paasche = rpi_unchained_paasche * 100;
	year = _n_ + &start - 1;
run;
%mend;
%create_chainedpaasche_indices(start=&start_year, end=&end_year);

*Create Fisher Index;
%macro create_chainedfisher_indices(start=, end=);
data rpi_fisher_onerow;
	merge rpi_laspeyres_onerow rpi_paasche_onerow;
	by obs;
run;

data rpi_fisher_onerow;
	set rpi_fisher_onerow;
	%do i=%eval(&start+1) %to &end;
	rpi_unchained_fisher_&i = (rpi_unchained_laspeyres_&i * rpi_unchained_paasche_&i)**(0.5);
	%end;
	keep obs %do i=%eval(&start+1) %to &end; rpi_unchained_fisher_&i %end;;
run;

data rpi_fisher_onerow;
	set rpi_fisher_onerow;
	rpi_chained_fisher_&start = 1;
	%do j=%eval(&start+1) %to &end;
			rpi_chained_fisher_&j = rpi_unchained_fisher_&j * rpi_chained_fisher_%eval(&j-1);
	%end;
	keep %do k=&start %to &end; rpi_chained_fisher_&k %end;;
run;

proc transpose data=rpi_fisher_onerow out=rpi_chained_fisher;
	var %do i=&start %to &end; rpi_chained_fisher_&i %end;;
run;

data rpi_chained_fisher;
	set rpi_chained_fisher(rename=(col1=rpi_chained_fisher));
	rpi_chained_fisher = rpi_chained_fisher * 100;
	year = _n_ + &start -1;
run;
%mend;
%create_chainedfisher_indices(start=&start_year, end=&end_year);

data rpi_chained_alltypes;
	merge rpi_chained_laspeyres(keep=year rpi_chained_laspeyres) rpi_chained_paasche (keep=year rpi_chained_paasche) 
			rpi_chained_fisher(keep=year rpi_chained_fisher);
	by year;
run;

data rpi_alltypes;
	merge rpi_imputed_alltypes rpi_chained_alltypes;
	by year;
run;

proc export data=rpi_laspeyres 
			outfile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\rpi_lonmart_laspeyres.xls"
			replace;
run;

proc export data=rpi_paasche 
			outfile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\rpi_lonmart_paasche.xls"
			replace;
run;

proc export data=rpi_alltypes
			outfile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\rpi_lonmart_imputation.xls"
			replace;
run;
