/*##########################
	Part 1 Reading Output
  ########################## */

/*Bone Marrow Transplants*/
/*
1. What Status is being modeled?
The Status being modeled is Status = 0.
Status is a binary event indicator for bone marrow transplant patients,
where 1 indicates that the disease-free survival time is observed (either because of death, relapse,
or the end of the study) and 0 indicates that the disease-free survival time is not observed
(for a variety of potential reasons).
Thus, the latter of these two is being modeled.

2. Based on the odds ratios, if T increases, what would happen to the likelihood of an 'Event' 
    (one of the values of 'Status')?
If T increases, the likelihood of Event of Status = 0 also increases. This is because
the odds ratio is greater than 1.

3. Is the relationship between T and Status significant at the .05 level?
Yes, this relationship is significant at the .05 level.

4. How do you know?
We know this relationship is significant because the p-value is less than .0001,
and this is also confirmed by the 95% Wald Confidence Limits
not containing the value 1.
*/
proc logistic data=sashelp.bmt;
	class group/param=reference;
	model status = group t;
run;

/*
5. Is there a significant difference between the counts of process failures
   between process A and Process B?
The difference between counts of process failures for Process A and Process B
is 1.6000 but this difference does not appear to be statistically significant.

6. How do you know?
We know that the difference in counts is not signficant because the p-values
with both the pooled and satterhwaite methods is > 0.05. 

Since the equality of variances indicates that the variances are not equal (p-value = 0.0002),
we would tend to use the satterwaite method to determine signifcance of difference in means,
but pooled vs. satterthwaite doesn't seem to be a very important distinction in this case because
the t-values and p-values are roughly the same for both methods.

*/
proc ttest data=sashelp.failure;
	class process;
	var count;
run;

/*
7. Which age group experienced the highest rate of Low Birth Weight?
Age Group 1 experienced the highest rate of low birth weight
(10.07% compared to 7.66 and 9.29%)

8. What percentage of smokers have babies with Low Birth Weight?
Answer = 9.17%

*/
proc freq data=sashelp.birthwgt;
	table smoking * lowbirthwgt;
	table AgeGroup * lowbirthwgt;
run;

/*
Given values (val1, val2, val3), what will be the outputs (outp1, outp2, outp3, outp4)?

val1 =Vina Del Mar, Chile
val2 =City of Calabasas, CA
val3 =Carnegie Mellon University
*/

data question_3;
	set Non_;
	outp1 = scan(val1,5);
	outp2 = index(val2,"CA");
	outp3 = substr(val3,-10);
	outp4 = index(upcase(val2),"CA");
run;
/*
9. outp1: blank (because count of 5 exceed number of words, which is 4)
10.outp2: 20
11.outp3: An error because negative position cannot be used with substr()
12.outp4: 9
*/


/*##########################
	Part 2 Analyzing Code
  ########################## */

/*See Questions at the bottom*/ 
proc contents data=sashelp.cars;

data cars01;
	set sashelp.cars;
/*Section 1*/
		if msrp >=40000 then highprice_car = 1;
		else if msrp >= 0 then highprice_car = 0;
		
		if mpg_highway >32 then efficient_mileage_car = 1;
		else if mpg_highway <= 32 then efficient_mileage_car = 0;
run;

/*Section 2*/
%let carvars = msrp highprice_car mpg_city mpg_highway efficient_mileage_car;

%macro bad_macro_name;
/*Section 3*/
%do x=1 %to 5;
	%let var=%scan(&carvars, &x, " ");
/*End Section 3*/

/*Section 4*/
	%if &x = 2 | &x =5 %then %do;
		proc logistic data=cars01;
			title "bad title 2";
			title2 "Model &x: ";
			class origin drivetrain;
			model &var (event='1') =weight enginesize horsepower length origin drivetrain;
		run;
		quit;
	%end;
/*End Section 4*/

/*Section 5*/
	%else %do;
		proc glm data=cars01;
			title "bad title 1";
			title2 "Model &x: ";
			class origin drivetrain;
			model &var = weight enginesize horsepower length origin drivetrain/solution;
		run;
		quit;
	%end;
/*End Section 5*/
%end;
%mend;

/*Section 6*/
%bad_macro_name;


/*
1. What kind of variables are being created in Section 1? Numeric or Character? 
   If numeric, continuous, ordinal or binary?
Answer = Numeric, binary.

2. Is the macro variable created in Section 2, GLOBAL or LOCAL?
Answer = Global. Created in a %let in "open" code

3. What is happening in Section 3?
Section 3 creates a Do Loop that iterates through the list of 5 variables (carvars)
from Section 2. The loop scans the list of variables to find the first, second, ... fifth variable
in the list and creates a new variable called "var" which is set equal to the
variable in that iteration.

This variable (var) and the iteration number (x) are fed into if, else statements in latter
sections for further conditional processing and procedures.

4. Explain the logic that occurs in Section 4.
Section 4 uses an if statement to test whether x is equal to 2 or 5 and, if so,
it perform a proc logisitic using the corresponding variable.

The conditional proc logisitic does not run if x is equal to 1, 3, or 4.

This makes sense because proc logisitic is used for modeling probabilities for
binary/indicator variables, and in this case, variables 2 and 5 (highprice_car and
efficient_mileage_car) are the only binary variables while variables 1, 3, and 4 are
continuous variables.

5. If Section 6 is submitted, how many regression models will be output?
Answer = 3, one model setting each of the continuous varaibales as the 
dependent variable in the model (MSRP, MPG_City, MPG_Highway)

6. Why might the two types of regression models be used in this case?
   HINT: What do the variables 2 and 5 have in common that the others do not?

The two types of regressions account for different types of variables.
Variables 1, 3, and 4 are continuous while variables 2 and 5 are binary.
*/
