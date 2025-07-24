/* Program: grpi - LondonMart - Computing Double-Imputation Fisher grpis
NOTE: This program requires predicted values from Hedonics models estimated in:
C:\Users\Luke Samy\Documents\Postdoctoral\Research Projects\rpi\STATA programs and output\grpi_london_auction_imputation.do 
*/
%let start_year=1895;
%let end_year=1914;
%let baseyear=1895;

proc import datafile="C:\Users\campi\Documents\Research\2-HPI\GRPI\grpi_lonmart_imputed.csv"
			out=lonmart_data
			replace;
run;

proc contents data=lonmart_data;
run;

*Create Laspeyres Indices;
%macro create_Laspeyres_grpi(start=, end=);
proc means data=lonmart_data;
	var %do i=&start %to &end; pp&i %end;;
	where year=&baseyear;
	output out=sum_pps sum=%do i=&start %to &end; sumpp&i %end;;
run;

data temp;
	set sum_pps;
	%do i=&start %to &end;
	grpi_&i = sumpp&i / sumpp&baseyear *100;
	%end;
	drop %do i=&start %to &end; sumpp&i %end;;
run;

proc transpose data=temp out=grpi_laspeyres;
	var %do i=&start %to &end; grpi_&i %end;;
run;

data grpi_laspeyres;
	set grpi_laspeyres;
	year = _n_;
	year = year + &start - 1;
	rename _name_ = year_string col1=grpi_laspeyres;
	label _name_=year_string;
run;
%mend;
%create_Laspeyres_grpi(start=&start_year, end=&end_year);

*Create Paasche Index;
%macro create_paasche_grpi(start=, end=);
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

data grpi_paasche;
	merge basesum_&baseyear sum_pps;
	by year;
run;

data grpi_paasche;
	set grpi_paasche;
	grpi_paasche = sumpp / basesum&baseyear * 100;
run;
%mend;
%create_paasche_grpi(start=&start_year, end=&end_year);

data grpi_imputed_alltypes;
	merge grpi_laspeyres grpi_paasche;
	by year;
	keep year grpi_laspeyres grpi_paasche;
run;

data grpi_imputed_alltypes;
	set grpi_imputed_alltypes;
	grpi_fisher = (((grpi_laspeyres / 100) * (grpi_paasche / 100))**0.5)* 100;
run;

proc gplot data=grpi_imputed_alltypes;
	plot (grpi_laspeyres grpi_paasche grpi_fisher) * year / overlay;
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
		grpi_unchained_laspeyres = sum_&i / sum_&j;
		grpi_unchained_laspeyres_&i = sum_&i / sum_&j;
		obs = _n_;
		keep obs grpi_unchained_laspeyres grpi_unchained_laspeyres_&i;
	run;
%end;

data grpi_laspeyres_onerow;
	merge %do i=%eval(&start+1) %to &end; sumchained_&i(drop=grpi_unchained_laspeyres) %end;;
	by obs;
run;

data grpi_unchained_laspeyres;
	set %do i=%eval(&start+1) %to &end; sumchained_&i(keep=grpi_unchained_laspeyres) %end;;
	year = _n_ + &start;
run;

proc transpose data=grpi_unchained_laspeyres out=temp;
	var grpi_unchained_laspeyres;
	id year;
run;

data temp;
	set temp;
	grpi_&baseyear = 1;
	grpi_%eval(&start+1) = _%eval(&start+1);
	%do j=%eval(&start+2) %to &end;
			grpi_&j = _&j * grpi_%eval(&j-1);
	%end;
	drop %do k=%eval(&start+1) %to &end; _&k %end;;
run;

proc transpose data=temp out=grpi_chained_laspeyres;
	var %do k=&start %to &end; grpi_&k %end;;
run;

data grpi_chained_laspeyres;
	set grpi_chained_laspeyres;
	grpi_chained_laspeyres = grpi_unchained_laspeyres * 100;
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
		grpi_unchained_paasche = sum_&i / sum_&j;
		grpi_unchained_paasche_&i = sum_&i / sum_&j;
		obs = _n_;
		keep obs grpi_unchained_paasche grpi_unchained_paasche_&i;
	run;
%end;

data grpi_paasche_onerow;
	merge %do i=%eval(&start+1) %to &end; sumchained_&i(drop=grpi_unchained_paasche) %end;;
	by obs;
run;

data grpi_unchained_paasche;
	set %do i=%eval(&start+1) %to &end; sumchained_&i(keep = grpi_unchained_paasche) %end;;
	year = _n_ + &start;
run;

proc transpose data=grpi_unchained_paasche out=temp;
	var grpi_unchained_paasche;
	id year;
run;

data temp;
	set temp;
	grpi_&baseyear = 1;
	grpi_%eval(&start+1) = _%eval(&start+1);
	%do j=%eval(&start+2) %to &end;
			grpi_&j = _&j * grpi_%eval(&j-1);
	%end;
	drop %do k=%eval(&start+1) %to &end; _&k %end;;
run;

proc transpose data=temp out=grpi_chained_paasche;
	var %do k=%eval(&start) %to &end; grpi_&k %end;;
run;

data grpi_chained_paasche;
	set grpi_chained_paasche;
	grpi_chained_paasche = grpi_unchained_paasche * 100;
	year = _n_ + &start - 1;
run;
%mend;
%create_chainedpaasche_indices(start=&start_year, end=&end_year);

*Create Fisher Index;
%macro create_chainedfisher_indices(start=, end=);
data grpi_fisher_onerow;
	merge grpi_laspeyres_onerow grpi_paasche_onerow;
	by obs;
run;

data grpi_fisher_onerow;
	set grpi_fisher_onerow;
	%do i=%eval(&start+1) %to &end;
	grpi_unchained_fisher_&i = (grpi_unchained_laspeyres_&i * grpi_unchained_paasche_&i)**(0.5);
	%end;
	keep obs %do i=%eval(&start+1) %to &end; grpi_unchained_fisher_&i %end;;
run;

data grpi_fisher_onerow;
	set grpi_fisher_onerow;
	grpi_chained_fisher_&start = 1;
	%do j=%eval(&start+1) %to &end;
			grpi_chained_fisher_&j = grpi_unchained_fisher_&j * grpi_chained_fisher_%eval(&j-1);
	%end;
	keep %do k=&start %to &end; grpi_chained_fisher_&k %end;;
run;

proc transpose data=grpi_fisher_onerow out=grpi_chained_fisher;
	var %do i=&start %to &end; grpi_chained_fisher_&i %end;;
run;

data grpi_chained_fisher;
	set grpi_chained_fisher(rename=(col1=grpi_chained_fisher));
	grpi_chained_fisher = grpi_chained_fisher * 100;
	year = _n_ + &start -1;
run;
%mend;
%create_chainedfisher_indices(start=&start_year, end=&end_year);

data grpi_chained_alltypes;
	merge grpi_chained_laspeyres(keep=year grpi_chained_laspeyres) grpi_chained_paasche (keep=year grpi_chained_paasche) 
			grpi_chained_fisher(keep=year grpi_chained_fisher);
	by year;
run;

data grpi_alltypes;
	merge grpi_imputed_alltypes grpi_chained_alltypes;
	by year;
run;

proc export data=grpi_laspeyres 
			outfile="C:\Users\campi\Documents\Research\2-HPI\GRPI\grpi_lonmart_laspeyres.xls"
			replace;
run;

proc export data=grpi_paasche 
			outfile="C:\Users\campi\Documents\Research\2-HPI\GRPI\grpi_lonmart_paasche.xls"
			replace;
run;

proc export data=grpi_alltypes
			outfile="C:\Users\campi\Documents\Research\2-HPI\GRPI\grpi_lonmart_imputation.xls"
			replace;
run;
