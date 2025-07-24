/* Hedonics regression and HPI calculation */

%let start_year=1895;
%let end_year=1914;
%let baseyear=1895;

proc import datafile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\hpi_lonmart_imputed.csv"
			out=lonmart_data
			replace;
run;

proc contents data=lonmart_data;
run;

*Create Laspeyres Indices;
%macro create_Laspeyres_HPI(start=, end=);
proc means data=lonmart_data;
	var %do i=&start %to &end; pp&i %end;;
	where year=&baseyear;
	output out=sum_pps sum=%do i=&start %to &end; sumpp&i %end;;
run;

data temp;
	set sum_pps;
	%do i=&start %to &end;
	HPI_&i = sumpp&i / sumpp&baseyear *100;
	%end;
	drop %do i=&start %to &end; sumpp&i %end;;
run;

proc transpose data=temp out=hpi_laspeyres;
	var %do i=&start %to &end; HPI_&i %end;;
run;

data hpi_laspeyres;
	set hpi_laspeyres;
	year = _n_;
	year = year + &start - 1;
	rename _name_ = year_string col1=hpi_laspeyres;
	label _name_=year_string;
run;
%mend;
%create_Laspeyres_HPI(start=&start_year, end=&end_year);



*Create Paasche Index;
%macro create_paasche_HPI(start=, end=);
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

data HPI_paasche;
	merge basesum_&baseyear sum_pps;
	by year;
run;

data HPI_paasche;
	set HPI_paasche;
	hpi_paasche = sumpp / basesum&baseyear * 100;
run;
%mend;
%create_paasche_HPI(start=&start_year, end=&end_year);

data HPI_imputed_alltypes;
	merge HPI_laspeyres HPI_paasche;
	by year;
	keep year hpi_laspeyres hpi_paasche;
run;

data HPI_imputed_alltypes;
	set HPI_imputed_alltypes;
	HPI_fisher = (((hpi_laspeyres / 100) * (hpi_paasche / 100))**0.5)* 100;
run;

proc gplot data=HPI_imputed_alltypes;
	plot (hpi_laspeyres hpi_paasche hpi_fisher) * year / overlay;
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
		hpi_unchained_laspeyres = sum_&i / sum_&j;
		hpi_unchained_laspeyres_&i = sum_&i / sum_&j;
		obs = _n_;
		keep obs hpi_unchained_laspeyres hpi_unchained_laspeyres_&i;
	run;
%end;

data hpi_laspeyres_onerow;
	merge %do i=%eval(&start+1) %to &end; sumchained_&i(drop=hpi_unchained_laspeyres) %end;;
	by obs;
run;

data hpi_unchained_laspeyres;
	set %do i=%eval(&start+1) %to &end; sumchained_&i(keep=hpi_unchained_laspeyres) %end;;
	year = _n_ + &start;
run;

proc transpose data=hpi_unchained_laspeyres out=temp;
	var hpi_unchained_laspeyres;
	id year;
run;

data temp;
	set temp;
	hpi_&baseyear = 1;
	hpi_%eval(&start+1) = _%eval(&start+1);
	%do j=%eval(&start+2) %to &end;
			hpi_&j = _&j * hpi_%eval(&j-1);
	%end;
	drop %do k=%eval(&start+1) %to &end; _&k %end;;
run;

proc transpose data=temp out=hpi_chained_laspeyres;
	var %do k=&start %to &end; hpi_&k %end;;
run;

data hpi_chained_laspeyres;
	set hpi_chained_laspeyres;
	hpi_chained_laspeyres = hpi_unchained_laspeyres * 100;
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
		hpi_unchained_paasche = sum_&i / sum_&j;
		hpi_unchained_paasche_&i = sum_&i / sum_&j;
		obs = _n_;
		keep obs hpi_unchained_paasche hpi_unchained_paasche_&i;
	run;
%end;

data hpi_paasche_onerow;
	merge %do i=%eval(&start+1) %to &end; sumchained_&i(drop=hpi_unchained_paasche) %end;;
	by obs;
run;

data hpi_unchained_paasche;
	set %do i=%eval(&start+1) %to &end; sumchained_&i(keep = hpi_unchained_paasche) %end;;
	year = _n_ + &start;
run;

proc transpose data=hpi_unchained_paasche out=temp;
	var hpi_unchained_paasche;
	id year;
run;

data temp;
	set temp;
	hpi_&baseyear = 1;
	hpi_%eval(&start+1) = _%eval(&start+1);
	%do j=%eval(&start+2) %to &end;
			hpi_&j = _&j * hpi_%eval(&j-1);
	%end;
	drop %do k=%eval(&start+1) %to &end; _&k %end;;
run;

proc transpose data=temp out=hpi_chained_paasche;
	var %do k=%eval(&start) %to &end; hpi_&k %end;;
run;

data hpi_chained_paasche;
	set hpi_chained_paasche;
	hpi_chained_paasche = hpi_unchained_paasche * 100;
	year = _n_ + &start - 1;
run;
%mend;
%create_chainedpaasche_indices(start=&start_year, end=&end_year);



*Create Fisher Index;
%macro create_chainedfisher_indices(start=, end=);
data hpi_fisher_onerow;
	merge hpi_laspeyres_onerow hpi_paasche_onerow;
	by obs;
run;

data hpi_fisher_onerow;
	set hpi_fisher_onerow;
	%do i=%eval(&start+1) %to &end;
	hpi_unchained_fisher_&i = (hpi_unchained_laspeyres_&i * hpi_unchained_paasche_&i)**(0.5);
	%end;
	keep obs %do i=%eval(&start+1) %to &end; hpi_unchained_fisher_&i %end;;
run;

data hpi_fisher_onerow;
	set hpi_fisher_onerow;
	hpi_chained_fisher_&start = 1;
	%do j=%eval(&start+1) %to &end;
			hpi_chained_fisher_&j = hpi_unchained_fisher_&j * hpi_chained_fisher_%eval(&j-1);
	%end;
	keep %do k=&start %to &end; hpi_chained_fisher_&k %end;;
run;

proc transpose data=hpi_fisher_onerow out=hpi_chained_fisher;
	var %do i=&start %to &end; hpi_chained_fisher_&i %end;;
run;

data hpi_chained_fisher;
	set hpi_chained_fisher(rename=(col1=hpi_chained_fisher));
	hpi_chained_fisher = hpi_chained_fisher * 100;
	year = _n_ + &start -1;
run;
%mend;
%create_chainedfisher_indices(start=&start_year, end=&end_year);



data hpi_chained_alltypes;
	merge hpi_chained_laspeyres(keep=year hpi_chained_laspeyres) hpi_chained_paasche (keep=year hpi_chained_paasche) 
			hpi_chained_fisher(keep=year hpi_chained_fisher);
	by year;
run;

data hpi_alltypes;
	merge hpi_imputed_alltypes hpi_chained_alltypes;
	by year;
run;

proc export data=hpi_laspeyres 
			outfile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\hpi_lonmart_laspeyres.xls"
			replace;
run;

proc export data=hpi_paasche 
			outfile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\hpi_lonmart_paasche.xls"
			replace;
run;

proc export data=hpi_alltypes
			outfile="C:\Users\campi\Documents\Research\2-HPI\Publications\EREH\replication files\Output\hpi_lonmart_imputation.xls"
			replace;
run;

