/*##########################
	Part 3 Adding Comments/Explaining Existing Code
  ########################## */
 
/*AT EACH SPOT IN THE CODE WHERE THERE IS A LETTER, WRITE A SENTENCE OR
  TWO EXPLAINING WHAT THE BLOCK OF CODE DIRECTLY BELOW THE LETTER IS 
  DOING. IF THERE IS A QUESTION, ANSWER IT.
*/
options validvarname=v7;
/*
A. Use a %let global macro to save the path location as a variable called directory
and then use this path in a libname statement to create a SAS library called "g" that
references files in the directory at the specified path.

  To the right of the equal sign, enter the location on your computer of
  the directory where you have saved the datasets downloaded from Canvas/Lobby.
  
  YOU MAY HAVE TO CHANGE THE DIRECTION OF THE FORWARD SLASH!!!
*/
%let directory = C:/Users/jeffr/Documents/SAS/Final;
libname g "&directory.";

/*
B. Run print and content procedures to help give an understanding of the data.
PROC PRINT generates an tabular output of all the data in the data set that is referenced.
In this case, it is ok to print all of the month and year data because these are small data sets.
PROC CONTENTS generates overviews of the data, including information like the number of
observations in a dataset, the number of variables, the variable names, variable types, and
variable formats (among other things).
*/
proc print data=g.months; run;
proc print data=g.years; run;
proc contents data=g.tract_month_medical_disp; run;
proc contents data=g.tract_month_retail_disp; run;
proc contents data=g.tract_nhood; run;


/*
C This procedure uses SQL langauge to create a new data set (called "dataset_C")
which will have a column for each variable in the select clause ("clause" is what it is called in SQL).
The procedure will create a cartesian product (a type of join) for the data sets tract_nhood, years, and months
because a join type (inner, outer, left, right) has not been specified in another clause.
The order by clause means the resulting data set will have all of the FIPS codes in order first,
and within the same FIPS codes, records will then be ordered by year and then by month.
*/
proc sql;
	create table dataset_C as	
	select fips,nbhd_name, year, month, monthname
	from g.tract_nhood, g.years, g.months
	order by fips , year, month;
quit;

/*
D This set of procedures and data sets merges three tables (data sets).
In order to merge correctly, the two data sets first need to be sorted by the variables that will be
used in the merge (which are the same variables sorted in the last section).
The If...Then statements are used to add "0" if an observation is not in the retail
or medical dataset, then the number of retail or medical dispensaries (respectively)
is set equal to 0.

*/
proc sort data = g.tract_month_retail_disp out=retails;
	by fips year month;
run;

proc sort data = g.tract_month_medical_disp out=medicals;
	by fips year month;
run;

data neighborhoods_disp ;
	merge dataset_C (in=c)
	      retails (in=b)
	      medicals (in=a);
	by fips year month;
	if a;
	
	if not b then retail_dispensaries = 0;
	if not a then medical_dispensaries = 0;
run;
/*End of D*/


/*
E This procedure creates a table or dataset called n_hood_disp0 that shows the mean number of
retail dispensaries and the mean number of medical dispensaries for every month and year combination for
each neighborhood.
*/
/*Sums of counts by class variables (neighborhood and year)*/
proc means data=neighborhoods_disp noprint;
	class nbhd_name year month;
	var retail_dispensaries medical_dispensaries;
	output out=nhood_disp0 sum= ;
run;

/*
F
What tables in your output window were produced in Section E? Why?

Answer: There were no tables produced in the output window because
the option "noprint" was given.
*/

/*
This procedure sorts the table produced in the last section by the variables listed in the "by" option
and keeps only the observations where _type_ = 7 and also removes the columns for _type_ and _freq_.
It gives a new name to this output data set so the original version is not replaced.
*/
proc sort data=nhood_disp0 out=nhood_disp (drop=_type_ _freq_);
	where _type_ = 7;
	by nbhd_name year month; 
run;

proc print data = nhood_disp0 (obs = 10);
run;

/*
H The import procedure reads in a file to create a SAS data set.
The dbms option tells the procedure that the input data type is csv.
The guessingrows option tells the procedure to use the first 200 rows
of data determine correct data types and lengths for each variable.

The proc contents and proc print can be used to ensure that the data was imported correctly
and that the variable types look appropriate.
*/
proc import out=sales
	file = "&directory./denver_residential_sale_transfers.csv"
	dbms=csv replace;
	guessingrows = 200;
run;

proc contents data=sales; run;
proc print data=sales (obs=100000 firstobs=99951); run;

/*
This data set creates a new variable (sale_date) in the sales data set that is equal to the first
day of the corresponding sale_month in the corresponding sale_year.
The sale_date variable is then formatted to show the first three letters of the month and year (in four digits).
*/
data sales;
	set sales;
	
	sale_date =mdy (sale_month,1,sale_year);
	format sale_date monyy7.;
run;

/*
J This procedure generates a fequency table for sale dates in the sales data set and
shows them in descending order (greatest frequency first).
Provide a title for this frequency
*/
proc freq data=sales order=freq;
	title "Frequency of Dates On Which Residential Sales Occurred";
	table sale_date;
run;

/*
K Which had the lowest number of sales?
Answer = January 2020
*/

/*You will
/*YOU WILL NEED THE FOLLOWING DATASETS IN SUBSEQUENT STEPS AND 
  AND ANALYSIS: 
  -NHOOD_DISP
  -DATASET_C
  -SALES
*/



/*##########################
	Part 4 Data Management and Analysis
  ########################## */
  
/* Task 3 */
proc import out=PROPERTY1 (keep = AREA_ABG ASSESS_VALUE BED_RMS BSMT_AREA CCAGE_RM CCYRBLT FBSMT_SQFT
FULL_B GRD_AREA HLF_B LAND_SQFT NBHD_1 NBHD_NAME OFCARD PIN PROPERTY_CLASS STORY TAX_DIST TOTAL_VALUE UNITS)
	file = "&directory./denver_housing_characteristics.csv"
	dbms=csv replace;
	guessingrows = 200;
run;

proc contents data=property1; title "Contents of Property1"; run;
proc print data=property1 (obs=100000 firstobs=99951); title "Property1 Table"; run;

/* PROPERTY1 has 189045 observations and 20 variables (which match the 20 I specfied in the keep option.
   Likewise, the print procedure shows that these observations in the middle of the table
   appear to look correctly filled in. */

/* Task 4 */
proc sql;
	create table transfers1 as	
	select *
	from property1 p inner join sales s
	on s.pin = p.pin;
quit;

proc contents data = transfers1; title "Contents of Transfers1"; run;
proc print data = transfers1 (obs = 10); title "Transfers1 Table"; run;

/* The SQL procedure seemed to run correctly. The new transfers1 data set has 35 variables which corresponds
to 17 variables from sales and 20 variables from property, minus 1 for the column the were joined on (pin)
and minus 1 more for NBHD_1, which is in both tables.

However, I am not doing anythign with NBHD_1 because the directions do not specify to do so. */


/* Task 5 */

	/* Parts A through G */
	data transfers1;
	set transfers1;
	where property_class in ("Condominium", "Single Family Residential",
"Rowhouses") and sale_year >= 2010 and sale_year <= 2019;
  	if sale_price =. then delete;
   	if sale_price <= 100 then delete;
	age = 2021 - sale_year;
	if property_class = "Condominium" then Is_Condo = 1; 
    else Is_Condo = 0;
  	if property_class = "Single Family Residential" then Is_SFR = 1; 
    else Is_SFR = 0;
  	if property_class = "Rowhouses" then Is_RowHouse = 1; 
    else Is_RowHouse = 0;
	if sale_year - ccage_rm <= 5 then renovated = 1;
	else renovated = 0;
	ln_price = log(sale_price);
	run;

	/* Check that the data set worked correctly. */
	proc freq data = transfers1;
	table property_class;
	title "Frequencies of Property Classes in Transfers1 Data Set";
	run;
	/* Only the three property types of interest remain. */
	proc print data = transfers1 (obs = 10); title "Transfers1 Table";
	run;
	/* The other variables seem to have been created correctly.*/


/* Task 6 */
proc univariate data=transfers1 noprint;
  var sale_price;
  output pctlpre=P_ pctlpts= 1, 99;
run;
proc print data=data2; title "Percentiles of Sale Price";
run;

/*  1st percentile is $42900.
	99th percentile is 1700000. */

data sales_and_attributes;
set transfers1;
where sale_price > 42900 and sale_price < 1700000;
run;

proc contents data = sales_and_attributes; title "Contents of Sales_and_Attributes Data Set";run;
/* Sales_and_Attributes has 129169 observations. */

	
/* Task 7 */
data dispensary;
set nhood_disp;
disp_total = retail_dispensaries + medical_dispensaries;
if retail_dispensaries >= 1 then has_retail_dispensary = 1;
else has_retail_dispensary = 0;
if medical_dispensaries >= 1 then has_medical_dispensary = 1;
else has_medical_dispensary = 0;
if retail_dispensaries >= 1 or medical_dispensaries >=1 then has_dispensary = 1;
else has_dispensary = 0;
run;

proc print data = dispensary (obs = 10); title "Dispensary Table";
run;

proc contents data = dispensary; title "Contents of Dispensary Data Set"; run;


/* Task 8 */
proc sql;
	create table sale_dispensary_merged as	
	select *
	from sales_and_attributes s left join dispensary d
	on s.nbhd_name = d.nbhd_name and s.sale_month = d.month and s.sale_year = d.year;
quit;

proc print data = sale_dispensary_merged(obs = 20);
title "Sale_Dispensary_Merged Table";
run;
/* The merge appeared to run correctly. */

/*  Sales_and_Attributes has 129169 observations.
	Dispensary has 6960.
	Sale_Dispensary_Merged has 129169. */

proc freq data = sale_dispensary_merged;
table has_dispensary;
title "Frequency of At Least One Dispensary";
run;
/* has_dispensary is NOT null or missing for far greater than 6960 observations. */

/* Thus, I would conclude that this is a one-to-many join where every one record
from the sales_and_attributes data set joins with many records from the dispensary data set. */


/* Task 9 */
proc contents data = g.dispensary_opening_dates_bynhood;
title "Contents of Dispensary_Opening_Dates_ByNHood"; run;

proc print data = g.dispensary_opening_dates_bynhood (obs=10);
title "Dispensary_Opening_Dates_ByNHood Table"; run;

data disp_open_dates;
set g.dispensary_opening_dates_bynhood;
run;

proc sql;
	create table int_file as	
	select *
	from sale_dispensary_merged s inner join disp_open_dates d
	on s.nbhd_name = d.nbhd_name;
quit;

proc print data=int_file (obs=30);
run;

/* Using an array of opening_date variables to test whether the time elapsed
between sale date and opening date is within 365 days (plus or minus).

Then, for each time elapsed, an indicator variable is made (0 or 1).

Then, for each record, if any of those indicator variables is 1, then analytic_record = 1.

The same idea is applied to sold_within_6months. */

data analytic_file;
set int_file;
array dates{17} opening_date1-opening_date17;
array elapsed{17} elapsed1-elapsed17;
array record{17} record1-record17;
array sixmonth{17} sixmonth1-sixmonth17;
do i = 1 to 17;
elapsed{i} = sale_date - dates{i};
end;
do i = 1 to 17;
if elapsed{i} >= -365 and elapsed{i} <= 365
then record{i} = 1;
else record{i} = 0;
if elapsed{i} >= 0 and elapsed{i} <= 182
then sixmonth{i} = 1;
else sixmonth{i} = 0;
end;
analytic_record = (1 in record);
sold_within_6months = (1 in sixmonth);
drop i elapsed1 elapsed2 elapsed3 elapsed4 elapsed5 elapsed6 elapsed7 elapsed8 elapsed9 elapsed10
elapsed11 elapsed12 elapsed13 elapsed14 elapsed15 elapsed16 elapsed17 record1 record2 record3 record4
record5 record6 record7 record8 record9 record10 record11 record12 record13 record14 record15 record16 record17
sixmonth1 sixmonth2 sixmonth3 sixmonth4 sixmonth5 sixmonth6 sixmonth7 sixmonth8 sixmonth9 sixmonth10 sixmonth11
sixmonth12 sixmonth13 sixmonth14 sixmonth15 sixmonth16 sixmonth17;
run;

data analytic_file;
set analytic_file;
where analytic_record = 1;
run;

/* There is likely a cleaner or shorter way to do this. However, I tried dozens of different options and
could not get any of them to work, so I went with a little more complex option here. */

proc print data = analytic_file(obs=30); title "Analytic_File Table"; run;

proc freq data = analytic_file; table analytic_record sold_within_6months; title "Frequency of Analytic_Record and 6-Month Sale"; run;

/* There are 48912 records in the analytic_file. About 40% of these records were sold within 6 months after a dispensary opening,
while the other 60% were not. */


/*#############
	Analysis
  ############# */


/* Task 10 */
proc means data = analytic_file n mean stddev min max;
var sale_price ln_price story age land_sqft area_abg bed_rms full_b hlf_b;
title "Summary Statistics for All Denver Houses in Analytic_File";
run;

/* Task 11 */

%MACRO plotvars (var=, fnote=);
proc sgplot data = analytic_file;
scatter x = &var y = ln_price / group = has_dispensary;
title "Correlation between &var and Log(price)";
xaxis label = "&var";
yaxis label = "Log(price)";
footnote "&fnote";
run;
%MEND plotvars;
/* I am choosing not to add a linear trendline above these plots because it turns out that some of these correlations are
not linear. While one could apply a linear trendline to some of these plots, it would perhaps be deceiving to apply it to all of them.
Since we are using a macro for this plotting, what we do to one, we must do to all, and I do not wish to apply a linear trendline
to all of these plots.*/

ods pdf file = "SAS_Final_JScanlon.pdf";

%plotvars(var=ccyrblt, fnote=%str(The correlation between the year the home was built and the log of sale price appears nonlinear and
non-monotonic. The average log of sale price appears to decrease gradually from the late 1880s to the 1970s. Then, the average log of sale price begins
to increase sharply from the 1970s onward. This could make the year the house was built a poor variable to include in a
linear regression model.));

%plotvars(var=disp_total, fnote=%str(One interesting observation from this plot is that the range of log of price decreases as
the total number of dispensaries increases. This may simply be due to the fact that the number of observations is also decreasing as the number of dispenaries increases.
Fewer observations can result in less variance in those observations. Thus, it is a little difficult to tell if a positive or negative correlation exists,
although it looks as though perhaps a slight positive relationship could exist.));

%plotvars(var=area_abg, fnote=%str(The correlation between area above ground and log of price is also nonlinear.
While the log of price experiences a sharp increase per unit increase in area above group across the range 0 to 2000, the slope of this relationship
becomes much less step over the range 2000 to 4000 sq ft. Thus, the marginal benefit to price of additional square footage beyond 2000 decreases. This
does not mean we cannot add this variable to a regression, but the linear model will only be able to capture so much.));

%plotvars(var=bed_rms, fnote=%str(The number of bedrooms in a house could technically be classified as either a categorical or continuous variable. However, it can certainly
be thought of as an ordinal variable because 3 bedrooms is typically considered more desirable than 2 bedrooms, which is more desirable than 1 bedroom. This plot shows this relationship
by showing an increase in log of price as the number of bedrooms increases. However, covariance can also be considered here because homes with more bedrooms also, for example, have more square footage
than homes with fewer bedrooms.));

%plotvars(var=full_b, fnote=%str(This scatterplot closely resembles the scatterplot in which Number of Bedrooms is the indenpendent variable. The same
discussion regarding variable type and covariance applies here as well. Likewise, as with the former scatterplot, this plot also provides
some detail about the distribution of the independent variable. There are very few homes with 6 or 7 full bathrooms, and even fewer with 8 or more.));

proc sgplot data = analytic_file;
VBOX  area_abg / category = hlf_b;
title "Distribution of Area Above Ground by the Number of Half-Bathrooms";
yaxis label = "Area Above Ground (Sq Ft)";
footnote "Homes with one half-bathroom and two half-bathrooms have similar distributions of area above ground. Thus,
the number of half-bathrooms could be an important factor contributing to sale price for two homes that are nearly identical in many other ways (including square feet).
The range for area above ground is much smaller for homes with three half-bahtrooms, and there are no outliers. This is likely because
there are much fewer observations in this category altogether. This also means there are many homes that have
greater area above ground but fewer half-bathrooms than the homes in this subset.";
run;

ods pdf close;

	
/* Task 12 */
proc univariate data = analytic_file;
var sale_price;
histogram / normal (color = red);
title "Distribution of Sale Price";
footnote "The distribution of sale_price is heavily right-skewed. This is because there are many homes
that fall within a reasonable or tpyical price range, but there are some homes that are very expensive, which
create a tail on the high end of the distribution and pull up the mean. Thus, the mean is greater than the median price.
The sale_price variable is not normally distributed, which is one reason why the authors likely performed a log transformation
of this variable, because this transformation can normalize skewed data.";
run;

proc univariate data = analytic_file;
var ln_price;
histogram / normal (color = red);
title "Distribution of Log(Price)";
footnote "The histogram for ln_price shows a normal distribution, meaning there is a bell-shaped curve
around the mean. The mean of this data is roughly 12.6. This corresponds to the peak of the curve and is also fairly close to the
peak of the histrogram bars.";
run;

/* Comments regarding the distributions of each variable (price and log of price) are written in the footnotes to each output. */


/* Task 13 */
PROC CORR data= analytic_file;
var sale_price ln_price story age land_sqft area_abg bed_rms full_b hlf_b;
title "Correlations Between Price and Several Continuous Variables";
footnote "Nearly all of the six continuous variables included in this procedure have a significant linear association with both
sale_price and ln_price. Nearly all of the p-values of interest in this correlation matrix are less than 0.0001, which is well above our threshold
for rejecting the null hypothesis that an association does not exist. The only exception is that there does not appear to be a significant linear association between
ln_price and land_sqft, since this p-value is 0.6943. A scatterplot of these two variables will show a nearly vertical relationship between the two, when
ln_price is plotted on the y-axis, which perhaps explains this exception.";
run;
/* Significant correlations:
	Sale price with story, age, land_sqft, area_abg, bed_rms, full_b and hlf_b.
	Ln_price with story, age, area_abg, bed_rms, full_b, hlf_b. 

	See footnote above for more information.*/


/* Task 14 */

/*I want to know which neighborhood I should set as my reference so I'm going to run a proc means to
determine which neighborhood had the lowest ln_price on average. */

/* Model 1 */
proc glm data=analytic_file;
class nbhd_name sale_month sale_year;
model ln_price = story age land_sqft area_abg bed_rms full_b hlf_b nbhd_name sale_month sale_year/solution;
title "Model 1: Property Values + Dummy Variables";
quit;


/* Model 2 */
proc glm data=analytic_file;
class nbhd_name sale_month sale_year;
model ln_price = story age land_sqft area_abg bed_rms full_b hlf_b nbhd_name sale_month sale_year disp_total/solution;
title "Model 2: Model 1 + Dispensary Total";
quit;


/* Model 3 */
proc glm data=analytic_file;
class nbhd_name sale_month sale_year sold_within_6months;
model ln_price = story age land_sqft area_abg bed_rms full_b hlf_b nbhd_name sale_month sale_year disp_total sold_within_6months/solution;
title "Model 3: Model 2 + Sold Within 6 Months Indicator";
quit;


/* Model 4 */
proc glm data=analytic_file;
class sale_month sale_year sold_within_6months;
model ln_price = disp_total story age land_sqft area_abg bed_rms full_b hlf_b sale_month sale_year sold_within_6months/solution;
title "Model 4: Model 3 without Neighborhood Dummy Variables";
quit;


/* Task 15 */
/*
	Models 1, 2, and 3 all performed about equally in terms of explanatory power. They all achieve an R-squared of slightly greater than 0.75, which means
these about 75% of the variation in ln_price is explained by the model. If judging them based only on R-squared, model 3 out-performs model 2, which in turn
out-performs model 1 (but only by a very small margin). In reality, regression models are almost always able to perform better when more and more explanatory variables
get added to the model, so sometimes adjusted R-squares are used to "penalize" the model by reducing the R-squared in accordance with the number of variables used. Thus, since
model 3 uses more variables than model 2, which uses more variables than model 1, perhaps the adjusted r-squares would return a different ranking.

	Model 4 does markedly poorer on R-squared compared to the other 3 models. This is because the dummy variables for each neighborhood, which for the most part of significant
predictors in the other 3 models, are removed from this model. Thus, model 4 does not control for all of these external factors that exist between neighborhoods in the same way that
the other 3 models can.

	In general, building properties and neighborhood seems to be significant predictors of log(price) across the board (for all of the models), although some small exceptions
may exist in some cases. In most cases, these predictors had p-vales less than 0.0001. One building proerty that was not a significant predictor of log(cost) was building age.
This might be because of the non-monotonic nature of the correlation shown in the scatterplot for building construction year.

	Sale Month is not often a signficant predictor of log(price), though it is interesting to point out the time of year when month is the most often signficant: winter. These dummy variables
were most often signficant in the winter and not signficant in warmer months, and the estimates was also negative in the winter, indicating that there is sufficient evidence to suggest that log(price)
is lower in the winter compared to warmer months. This might make sense, since anecdotally we know that real estate sales are slower and less in demand in the winter but usually boom in the spring and summer.

The variable for the total number of dispensaries has a significant p-value (<.0001) and the estimate has a positive sign, meaning each additional dispensary increases, on average, the log of sale price. Compared to
other estimates, this coefficient appears small, but considering that other variables are a simple binary (0 or 1), and that the coefficient for disp_total applies to each additional unit, the impact of 3 or 4 additional
dispensaries could feel quite substantial and have a material impact on sale price. This positive impact is also identified by the authors of the paper.

The indicator for selling a home within six months also has a positive and signficant impact on log of price (p-value of 0.0005). This is not so surprising as homes that sell quickly (within six months) are most likely more
attractive or competitive in the marketplace than those that take a while to sell (greater than six months). A more competitive place in the market means sellers might be less willing to negotiate the price downwards and may have
leverage to make a higher asking price. 


