/* Name: Jeff Scanlon*/

/* Create a new SAS library */
libname hw5 "C:\Users\jeffr\Documents\SAS\Week5";
run;

/* Check Contents to understand number of variables, variable names, number of observations, etc. */

proc contents data = hw5.urbancore_2000 (obs = 25);
run;

proc contents data = hw5.urbancore_2015 (obs = 25);
run;


/* The datasets have two variables related to Percent of people with bachelors degrees and diplomas,
but they use different variable names for these two datasets. Thus, we will need to change the variable
names on one of the datasets to match the other. */

/* I will make "pct_bachdegree_ormore" and "pct_diploma_ormore" equal to "pct_bachdegree_orhigher"
and "pct_diploma_orhigher." */

/* Create temporary data sets to work with and rename two of the variable in 2000*/
data uc2000;
set hw5.urbancore_2000;
rename pct_bachdegree_ormore = pct_bachdegree_orhigher pct_diploma_ormore = pct_diploma_orhigher;
run;

data uc2015;
set hw5.urbancore_2015;
run;

/* Create a new table that combines the two datasets by stacking and creates a new variable for year. */
/* Also do a log transformation on several variables because, as will be shown later,
	these variables are highly right-skewed and log transformation normalizes right-skewed data. */
/* The log transformation is also done by the research paper authors */
/* Small value (1E-16) is to handle undefined cases of log(0) */
data uc_combined;
set uc2000 (IN = year2000)
	uc2015 (IN = year2015);
	if year2000 = 1 then year = 2000;
	if year2015 = 1 then year = 2015;
	array oldvars {6} pct_commute_pubtrans pct_commute_walk pct_commute_car
	pct_commute_bike unemployment_rate median_hhincome;
	array newvars {6} log_commute_pubtrans log_commute_walk log_commute_car
	log_commute_bike log_unemployment log_income;
	do i = 1 to 6;
	if oldvars{i} > 0 then newvars{i} = log(oldvars{i});
	else newvars{i} = 0.000000000000000001;
	end;
run;


/* Create a new binary indicator variable for Year to use in a regression later on. */
data uc_combined;
set uc_combined;
if year = 2000 then year_ind = 0;
if year = 2015 then year_ind = 1;


/* Run a frequency table on all of the categorical variables. */
ods rtf file = "assignment5_report.rtf";
proc freq data = uc_combined;
title "State Frequencies";
table st;
run;

/* Run a PROC MEANS to get summary statistics for all numeric variables. */
proc means data = uc_combined N mean std stderr median min max;
class year;
var median_hhincome pct_1person_hh pct_amerind pct_asian pct_bachdegree_orhigher pct_black
	pct_commute_bike pct_commute_car pct_commute_home pct_commute_pubtrans pct_commute_walk    
	pct_diploma_orhigher pct_hisp pct_owner pct_renter pct_white pop_18to39 sqmi total_workers    
	totpop travel_time_to_work unemployment_rate;
title "Summary Statistics for Continuous Variables";
run;

/* Run Proc Univariate on certain variables of particular interest to better understand their distribution. */
proc univariate data = uc_combined;
var median_hhincome log_income;
histogram / normal (color = red);
title "Distribution of Househould Income (and Log Transformed Income)";
run;

/* These results indicate both increases and decreases in the mean for different variables (depending on the variable)
from 2000 to 2015. However, in order to test whether these differences are statistically significant, a paired
t-test will need to be performed, which will be done later. */


/* Correlation scatter plot (and histogram) to understand correlation in variables. */
proc sgscatter data=uc_combined; 
matrix median_hhincome pct_bachdegree_orhigher
	pct_commute_car unemployment_rate travel_time_to_work /group=year diagonal=(histogram kernel);
	title "Correlation Scatterplots for Variables of Interest";
run;

/* There are so many variables to consider correlations for, so I ran the proc
a second time with different variables so as not to crowd a single plot */
proc sgscatter data=uc_combined; 
matrix pct_white pct_commute_pubtrans pct_diploma_orhigher pct_renter  
	pop_18to39 total_workers /group=year diagonal=(histogram kernel);
	"Correlation Scatterplots for Variables of Interest, continued";
run;


proc sgplot data = uc_combined;
scatter x = pop_18to39 y = total_workers / group = year;
title "Correlation between Young Adult Population and Total Workers, by Study Year";
xaxis label = "Population (Age 18-39)";
yaxis label = "Total Number of Workers";
run;


proc sgplot data = uc_combined;
VBOX travel_time_to_work / category = year;
title "Distribution of Travel Times to Work, by Study Year";
yaxis label = "Travel Time to Work";
run;

proc sgplot data = uc_combined;
VBOX pct_diploma_orhigher / category = year;
title "Distribution of Percent of Residents with High School Diplomas or Higher";
yaxis label = "Percent of Residents w/ H.S. Diploma or Higher";
run;

proc sgplot data= uc_combined;
  bubble x=pct_white y=pct_commute_home size=median_hhincome / group=year 
    transparency=0.4;
  inset "Bubble size represents Median Household Income" / position=bottomright textattrs=(size=11);
  title "Positive Correlation between White Residents and Residents Working from Home";
  yaxis grid label = "Percent White Residents";
  xaxis grid label = "Percent Working from Home";
run;


/* Need to create a new dataset for several reasons:*/

/* 1. Eventually, have to run a paired t-test for this data. Thus, need to make a new dataset
that is not stacked from 2000 and 2015, but rather adds additional columns. */

/*The join and subsequent use of the dataset will require renaming the variables in one of the datasets. */

/* I also want the data in a different format (not stacked) in order to produce a specific type of
visualization and to be able to create variables like change in X from 2000 to 2015.*/

/* Creating a new 2015 dataset with new variable names to be hoined to 2000.*/
/* My collaborators discussed using a Macro for this, but I decided to just use Rename instead. */
data uc_2015_v2;
set uc2015;
rename st = y15_st pct_white = y15_pct_white pct_black = y15_pct_black pct_amerind = y15_pct_amerind 
		pct_asian = y15_pct_asian pct_hisp = y15_pct_hisp pct_commute_car = y15_pct_commute_car
		pct_commute_pubtrans = y15_pct_commute_pubtrans pct_commute_bike = y15_pct_commute_bike
		pct_commute_walk = y15_pct_commute_walk pct_commute_home = y15_pct_commute_home
		pct_diploma_orhigher = y15_pct_diploma_orhigher pct_bachdegree_orhigher = y15_pct_bachdegree_orhigher
		pct_owner = y15_pct_owner pct_renter = y15_pct_renter pct_1person_hh = y15_pct_1person_hh
		unemployment_rate = y15_unemployment_rate median_hhincome = y15_median_hhincome
		travel_time_to_work = y15_travel_time_to_work totpop = y15_totpop
		pop_18to39 = y15_pop_18to39 sqmi = y15_sqmi total_workers = y15_total_workers Tracts = y15_Tracts
		log_commute_pubtrans = y15_log_commute_pubtrans log_commute_walk = y15_log_commute_walk
		log_commute_car = y15_log_commute_car log_commute_bike = y15_log_commute_bike
		log_unemployment = y15_log_unemployment log_income = y15_log_income;
run;

/* Join the new table to 2000 dataset. */
proc sql;
create table uc_joined as
select *
from uc2000 y00
left join uc_2015_v2 y15
on y00.NAME = y15.NAME;
quit;

/* Create new variables that are changes in X from 2000 to 2015 */
data uc_joined;
set uc_joined;
time_diff = y15_travel_time_to_work - travel_time_to_work;
diploma_diff = y15_pct_diploma_orhigher - pct_diploma_orhigher;
run;

/* Subset data for better visualization. */
data uc_joined_upper;
set uc_joined;
where time_diff > 20;
run;


/* Sort data for better visualization. */
proc sort data = uc_joined_upper;
by time_diff;
run;

proc sgplot data=uc_joined_upper noborder; 
  scatter y=NAME x=travel_time_to_work /
               markerattrs=(symbol=circlefilled);
  scatter y=NAME x=y15_travel_time_to_work /
               markerattrs=(symbol=circlefilled);
highlow y=NAME low=travel_time_to_work high = y15_travel_time_to_work;
  yaxistable NAME / location=outside
              position=left pad=10 valuejustify=right ;
  xaxis min=0 grid offsetmin=0 label='Travel Time to Work';
  yaxis fitpolicy=none valueattrs=(size=7) reverse display=none;
  title  "Change in Travel Times to Work (2000 - 2015)";
  title2  "For UC's with Increase of > 20 Minutes";
run;


PROC CORR data= uc_combined;
var pct_black year_ind median_hhincome travel_time_to_work
pct_bachdegree_orhigher pct_commute_pubtrans pct_commute_home;
title "Correlations Between Several Variables";
run;

/* We need to run a paired t-test to ensure control for differences across urban cores. */
/* Rather than running all of the possible t-tests, we will just choose some of the most
likely indicators of gentrification and transit change. */
PROC TTEST DATA=uc_joined ALPHA=.05;
    PAIRED 	pct_black * y15_pct_black
			median_hhincome * y15_median_hhincome
			travel_time_to_work * y15_travel_time_to_work
			pct_diploma_orhigher * y15_pct_diploma_orhigher
			pct_commute_home * y15_pct_commute_home;
run;

PROC REG data=uc_combined;
model log_commute_car = year pct_owner pop_18to39 pct_white pct_bachdegree_orhigher log_income log_unemployment;
title "Regression of Log(Percent Car Commuting) on Other Variables";
run;

/* Exluding these regressions from file

PROC REG data=uc_combined;
model log_commute_walk = year_ind pct_owner pop_18to39 pct_white pct_bachdegree_orhigher log_income log_unemployment;
run;


PROC REG data=uc_combined;
model log_commute_bike = year_ind pct_owner pop_18to39 pct_white pct_bachdegree_orhigher log_income log_unemployment;
run;


PROC REG data=uc_combined;
model log_commute_pubtrans = year_ind pct_owner pop_18to39 pct_white pct_bachdegree_orhigher log_income log_unemployment;
run;


PROC REG data=uc_combined;
model pct_commute_home = year_ind pct_owner pop_18to39 pct_white pct_bachdegree_orhigher log_income log_unemployment;
title "Regression of Percent Working from Home on Other Variables";
run;
*/

PROC REG data=uc_combined;
model travel_time_to_work = year pct_owner pop_18to39 pct_white pct_bachdegree_orhigher log_income log_unemployment;
title "Regression of Commuting Time on Other Variables";

run;
ods rtf close;
ods listing;

