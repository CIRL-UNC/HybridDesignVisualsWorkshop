/*Trimming down and reorganizing the trial and target population data*/


OPTIONS NOFMTERR;

/*Assigning the library where the cohort data is held*/

LIBNAME cohort "C:\Users\webst\OneDrive\Documents\SER seminar data\Trial";

/*Assigning the library where the target population data is held*/

LIBNAME targ "C:\Users\webst\OneDrive\Documents\SER seminar data\Target";


/*First, we use a PROC SQL statement to join the covariate and KRAS trial data sets*/

PROC SQL;
	create table trialcohortv1 as
		select a.*, b.BMMTR1 as KRAS from
			cohort.adsl_pds2019 as a left join cohort.biomark_pds2019 as b
				on a.subjid = b.subjid;
QUIT;

/*Next, we turn that data into our analytic trial data set, trimming some extraneous covariates and renaming others*/

DATA cohort.analytictrialcohort;
	SET trialcohortv1;

	intrial = 1; /*This is our trial indicator variable*/


	/*Now to recode some key covariates to numerical quantities to make some figures easier to make*/

	IF KRAS = " " OR KRAS = "Failure" THEN WildKRAS = .; /*First, wild-type KRAS*/
	ELSE IF KRAS = "Wild-type" THEN WildKRAS = 1;
	ELSE WildKRAS = 0;


	IF trt="FOLFOX alone" THEN treatment = 0; /*Next, treatment*/
	ELSE treatment = 1;

	IF diagtype = "Colon" THEN colon = 1; /*Next, colon cancer site (colon vs rectum)*/
	ELSE colon = 0;

	IF sex = "Male" THEN female = 0; /*Next, sex*/
	ELSE female = 1;

	IF livermet = "Y" THEN livermets = 1; /*And liver metastases*/
	ELSE livermets = 0;

	/*Next, we output those with no missing values for our new covariates*/

	IF WildKRAS ^= . AND female ^= . AND colon ^= . AND livermets ^= . AND age ^= . THEN OUTPUT;

	/*Now we just keep our new variables, as well as the progression-free survival data*/

	KEEP intrial treatment WildKRAS female colon livermets  age pfsdycr pfscr;
RUN;

/*Next, we need to change the target population data in a similar manner*/

DATA targ.analytictargcohort;
	SET targ.seerworkshop;

	/*Assinging a 0 value to the intrial variable*/

	intrial = 0;

	age = final_interval_age_calculated; /*Reshaping age*/

	IF Site_recode_ICD_O_3_WHO_2008 = 26 OR Site_recode_ICD_O_3_WHO_2008 = 25 THEN colon = 0;
	ELSE colon = 1; /*Recoding the site of cancer variables to a 1/0 setup akin to the trial*/

	IF sex = 2 THEN female = 1;
	ELSE female = 0; /*Recoding sex to be recorded the same as the trial*/

	IF SEERCombinedMetsatDX_liver_2010 >= 1 THEN livermets = 1; /*Recoding liver metastases*/
	ELSE livermets = 0;

	/*Unfortunately, we don't have data on KRAS genes in the target. Let's suppose it's present in about 90% of individuals. We
	can create it randomly using some SAS functions*/

	CALL STREAMINIT(12355); /*Setting our seed*/
	randKRAS = RAND('Uniform'); /*Drawing from the uniform distribution*/
	IF randKRAS <= 0.9 THEN WildKRAS = 1;
	ELSE WildKRAS = 0;

	/*Next, we output those with no missing values for our new covariates*/

	IF WildKRAS ^= . AND female ^= . AND colon ^= . AND livermets ^= . AND age ^= . THEN OUTPUT;


	KEEP intrial female colon livermets age WildKRAS;
RUN;
