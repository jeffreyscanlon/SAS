libname d "/folders/myfolders/sasdata/week4";
*libname wk4 "\\nas.heinz.local.cmu.edu\lobby\Courses\94-827\Dataset\week4";

/*From documentation I can set up formats*/
proc format ;
	value rac
           1 ="White alone"                          
           2 ="Black or African American alone"          
           3 ="American Indian alone"                    
           4 ="Alaska Native alone"                      
           5 ="American Indian and Alaska Native" 
           6 ="Asian alone"                             
           7 ="Native Hawaiian and Other Pacific Islander alone"
           8 ="Some Other Race alone"                 
           9 ="Two or More Races"
           ;
           
    value gend
    	2 = "female"
    	1 = "male";
quit;

/*******************************************************/
/*4. ODS - Output Delivery System */
/*******************************************************/

/*Turning on ODS TRACE tells SAS to print information
  on output object.*/
ODS trace on;

/*Work with Pennsylvania Income data*/
proc contents data=d.income2013pa; run;

/* When the trace is on the following is printed to the
 * log. There are 3 tables in the Results window, and
 * 3 corresponding output objects listed in the log.
 * Each object has a Name, Label, Template, and Path
 * Output Added:
 -------------
 Name:       Attributes
 Label:      Attributes
 Template:   Base.Contents.Attributes
 Path:       Contents.DataSet.Attributes
 -------------
 
 Output Added:
 -------------
 Name:       EngineHost
 Label:      Engine/Host Information
 Template:   Base.Contents.EngineHost
 Path:       Contents.DataSet.EngineHost
 -------------
 
 Output Added:
 -------------
 Name:       Variables
 Label:      Variables
 Template:   Base.Contents.Variables
 Path:       Contents.DataSet.Variables
 ------------- 
 */

/* 4a. Now that I know the names of the objects, I can 
       save the contents to a dataset.
 */
proc contents data=d.income2013pa;

ods output contents.Dataset.variables=work.Variables_in_mydataset;
run;

/* 4b. If I only want to print the Variables and not the engine
	   and dataset attributes then I use the ods Select statement.*/
proc contents data=d.income2013pa;
	ods select Contents.Dataset.variables;
run;

/* I can also use the ODS EXCLUDE statement to do the opposite.
   That is exclude the objects I do not want instead of SELECTing
   the object I want to keep.*/
proc contents data=d.income2013pa;
	ods exclude Contents.DataSet.EngineHost Contents.DataSet.Attributes;
run;

/*Note that multiple objects are listed on one statement */

ods trace off;

/* 4c. Examples of output datasets using common procedures
*/
/*TABULATE*/
ods trace on;
proc tabulate data=d.income2013pa; 
	VAR inctot;		
    CLASS sex age; 
    TABLE  MEAN*inctot*(age ALL),sex ALL; 
    where inctot>0 & inctot<900000;
run;
/* The object's path is Tabulate.Report.Table*/


proc tabulate data=d.income2013pa; 
	VAR inctot;		
    CLASS sex age; 
    TABLE  MEAN*inctot*(age ALL),sex ALL; 
    where inctot>0 & inctot<900000;
    ods output Tabulate.Report.Table = income_sex_age;
run;
/*Note that the output dataset is in LONG format, but the table
  itself is has 3 columns for sex and about 80 for age*/
 
 

 /*FREQ*/
proc freq data=d.income2013pa;
	table sex race;
	format sex gend. race rac.;
run;

/*Notice that there is an object for each variable/frequency table in
  the procedure. They are numbered Table1, Table2, and so forth . . .*/
 
/*
 Output Added:
 -------------
 Name:       OneWayFreqs
 Label:      One-Way Frequencies
 Template:   Base.Freq.OneWayFreqs
 Path:       Freq.Table1.OneWayFreqs
 -------------
 
 Output Added:
 -------------
 Name:       OneWayFreqs
 Label:      One-Way Frequencies
 Template:   Base.Freq.OneWayFreqs
 Path:       Freq.Table2.OneWayFreqs
 -------------
 */

/*You can SELECT one table to display and OUTPUT another.*/
title "Gender, Pennsylvania 2013";
proc freq data=d.income2013pa;
	table sex race;
	format sex gend. race rac.;
	ods select Freq.Table1.OneWayFreqs;
	ods output Freq.Table2.OneWayFreqs = freq_dataset_race;
run;

title "Gender, Pennsylvania 2013";
proc freq data=d.income2013pa;
	table sex race;
	format sex gend. race rac.;
	ods select Freq.Table1.OneWayFreqs;
	/*You can also output multiple objects per OUTPUT statement*/
	ods output Freq.Table2.OneWayFreqs = freq_dataset_race
			   Freq.Table1.OneWayFreqs = freq_dataset_gend;
run;

/*MEANS*/
title "Income by Gender";
proc means data=d.income2013pa n p5 p25 p75 p95;
	class sex;
	var inctot;
	format sex gend. ;
	ods output Means.Summary = income_by_gender;
run;


title "Income by Gender";
proc means data=d.income2013pa n p5 p25 p75 p95;
	class sex;
	var inctot;
	format sex gend. ;
	/*This produces a dataset of your output table as it appears in 
	  the output window.*/
	ods output Means.Summary = income_by_gender;
	
	/*This produces a dataset that produces the base summmary
	  stats in long format, unless you explicitly specify the stats
	  you want. It also produces stats for each level of the CLASS
	  statement, including ALL classes combined.*/
	output out = different_dataset ;
run;

/*SUMMARY*/
/*PROC SUMMARY does the same things as PROC MEANS, but produces
  a summary dataset instead, which we must specify using the OUTPUT OUT=
  statement. Notice below how each summary stat must be requested 
  in order for it to appear in the summary dataset created.*/
title "Income by Gender";

proc summary data=d.income2013pa n p5 p25 p75 p95;
	class sex;
	var inctot;
	format sex gend. ;
	output out=summary_example1;
	
run;
proc summary data=d.income2013pa n p5 p25 p75 p95;
	class sex;
	var inctot;
	format sex gend. ;
	output out=summary_example2 
		n   =inctot_n
		p5  =inctot_p5
		p25 =inctot_p25
		p75 =inctot_p75
		p95  =inctot_p95;
	
run;

/*Note the different layouts of summary examples1 and 2.*/
title2 "Example1";
proc print data = summary_example1; run;
title2 "Example2";
proc print data = summary_example2; run;

title2;


/* 4d External file types */
/* These statements set the destination of the output. Statements within
   the procedures select which SAS objects will be printed or saved to datsets.*/
/* Use ODS HTML to create output in an hypertext markup language file */


ods html file="/folders/myfolders/sasoutput/html_example.html";
	/*My folder location on my computer*/
title1 "Gender in PA";
proc freq data=d.income2013pa;
	table sex;
	format sex gend.;
run;
ods html close;

/* Use ODS RTF to create output in an rich text format file */
ods rtf file="/folders/myfolders/sasoutput/rtf_example.rtf";
title1 "Gender in PA";
proc freq data=d.income2013pa;
	table sex;
	format sex gend.;
run;
ods rtf close;

/* Use ODS PDF to create output in an portable document file */
ods pdf file="/folders/myfolders/sasoutput/pdf_example.pdf";
title1 "Gender in PA";
proc freq data=d.income2013pa;
	table sex;
	format sex gend.;
run;
ods pdf close;

/* Use ODS tagsets.excelxp to create output in an XML file */
ods tagsets.ExcelXP file="/folders/myfolders/sasoutput/excel_example.xml";
title1 "Gender in PA";
proc freq data=d.income2013pa;
	table sex;
	format sex gend.;
run;
ods tagsets.ExcelXP close;


/***************************************************************/
/* 4e. Exporting */
/***************************************************************/
/*Create extract that will be exported */
data income2013_extract;
	set d.income2013pa;
	
	if _N_ le 100;
run;

/*Create CSV, TXT and XLSX versions of the extract*/
proc export data= income2013_extract
	outfile = "/folders/myfolders/sasoutput/incomeextract.csv"
	dbms = csv replace;
run;

proc export data= income2013_extract
	outfile = "/folders/myfolders/sasoutput/incomeextract.txt"
	dbms = tab replace;
run;

proc export data= income2013_extract
	outfile = "/folders/myfolders/sasoutput/incomeextract.xlsx"
	dbms = xlsx replace;
	sheet = "newsheet";
run;

/**************************************************/
/* 4f CORR and  UNIVARIATE */
/**************************************************/

title "Scores Correlations";
ods trace on;
proc corr data=d.testdata;
	var algebra1_score biology_score engl_score;
run;
/*Notice the names of the objects*/

/*if we enable Graphics we can get plots*/
ods graphics on;
proc corr data=d.testdata plots=scatter;
	var algebra1_score biology_score engl_score;
run;
ods graphics off;

/*3 more output objects were added to our list, one for each
  pairing of variables. 
  
  The scatter plots suggest that we have some outliers that
  we should handle before moving forward with our analysis.
  
  Generally speaking, it appears that biology and algebra1
  are correlated with each other, and algebra1 is somewhat correlated
  with English.
 */


title "Age and observation weight Distribution";
proc univariate data=d.income2013pa;
	var age perwt;
	histogram;
run;

/*The histogram statement produces a histogram for each variable 
 on the var statement*/
/* All of the objects from the log:
 Output Added:
 -------------
 Name:       Moments
 Label:      Moments
 Template:   base.univariate.Moments
 Path:       Univariate.AGE.Moments
 -------------
 
 Output Added:
 -------------
 Name:       BasicMeasures
 Label:      Basic Measures of Location and Variability
 Template:   base.univariate.Measures
 Path:       Univariate.AGE.BasicMeasures
 -------------
 
 Output Added:
 -------------
 Name:       TestsForLocation
 Label:      Tests For Location
 Template:   base.univariate.Location
 Path:       Univariate.AGE.TestsForLocation
 -------------
 
 Output Added:
 -------------
 Name:       Quantiles
 Label:      Quantiles
 Template:   base.univariate.Quantiles
 Path:       Univariate.AGE.Quantiles
 -------------
 
 Output Added:
 -------------
 Name:       ExtremeObs
 Label:      Extreme Observations
 Template:   base.univariate.ExtObs
 Path:       Univariate.AGE.ExtremeObs
 -------------
 
 Output Added:
 -------------
 Name:       Histogram
 Label:      Panel 1
 Template:   base.univariate.Graphics.Histogram
 Path:       Univariate.AGE.Histogram.Histogram
 -------------
 
 Output Added:
 -------------
 Name:       Moments
 Label:      Moments
 Template:   base.univariate.Moments
 Path:       Univariate.PERWT.Moments
 -------------
 
 Output Added:
 -------------
 Name:       BasicMeasures
 Label:      Basic Measures of Location and Variability
 Template:   base.univariate.Measures
 Path:       Univariate.PERWT.BasicMeasures
 -------------
 
 Output Added:
 -------------
 Name:       TestsForLocation
 Label:      Tests For Location
 Template:   base.univariate.Location
 Path:       Univariate.PERWT.TestsForLocation
 -------------
 
 Output Added:
 -------------
 Name:       Quantiles
 Label:      Quantiles
 Template:   base.univariate.Quantiles
 Path:       Univariate.PERWT.Quantiles
 -------------
 
 Output Added:
 -------------
 Name:       ExtremeObs
 Label:      Extreme Observations
 Template:   base.univariate.ExtObs
 Path:       Univariate.PERWT.ExtremeObs
 -------------
 
 Output Added:
 -------------
 Name:       Histogram
 Label:      Panel 1
 Template:   base.univariate.Graphics.Histogram
 Path:       Univariate.PERWT.Histogram.Histogram
 -------------
 */

/*Using the 'plots' option on the univariate statement
  produces several charts in addition to the histogram*/
proc univariate data=d.income2013pa plots;
	var age perwt;
	histogram;
run;

/*The histogram statement has options:
	normal -adds a normal curve to the graph. 
	endpoints specifies the bins for the histogram.
	Quite a bit of manipulation can occur. These are just 2 examples.
*/
title "score distribution";
proc univariate data=d.testdata plots;
	var algebra1_score;
	histogram/normal (color=red)  
			  endpoints = 0 to 170 by 5;
run;


/*If we omitted outliers, things look a bit different*/

proc univariate data=d.testdata plots;
	where 30 < algebra1_score < 100 ;
	var algebra1_score;
	histogram/normal (color=red)  
			  endpoints = 0 to 170 by 5;
run;


/*Let's output the last histogram with outliers omitted to
  a pdf.
  
  Also we want to separate the scores into tertiles. Let's
  identify the 33rd and 67th percentile scores. For this
  we use the common OUTPUT OUT= statement. For the
  UNIVARIATE procedure the keywords pctlpts outputs the 
  percentile values that we specify (1 to 100 is available).
  pctlpre appends a prefix to the output variable names. The output
  dataets 'score_percentiles' should have 1 observation with 2 variables.*/
 ods pdf file="/folders/myfolders/sasoutput/score_histogram_omittingoutliers.pdf";
 title "Algebra1 Score distribution, Omitting outliers";
 proc univariate data=d.testdata plots;
	where 30 < algebra1_score < 100 ;
	var algebra1_score;
	histogram/normal (color=red)  
			  endpoints = 0 to 170 by 5;
	output out=score_percentiles pctlpts= 33 67 pctlpre=percentile_ ;
	ods select Univariate.algebra1_score.Histogram.Histogram
			Univariate.algebra1_score.Histogram.Normal.ParameterEstimates
			
			Univariate.algebra1_score.Histogram.Normal.Goodnessoffit;
run;
 ods pdf close;
 
 