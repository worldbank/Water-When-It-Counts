/*******************************************************************************
*								MOZ PROIRRI 								   *
*   					  REPLICATION MASTER DO-FILE						   *
*   							   2018										   *
********************************************************************************


********************************************************************************
*						   SELECT PARTS TO RUN   							   *
********************************************************************************/
	
	* select which parts of this do-file to run
	local 	packages			1	// Install packages -- only needs to be ran once in each computer
	local	attrition			1	// Run attrition test
	local 	balance_tables	 	1	// Create balance tables
	local	descriptives		1 	// Create descriptive statistics graphs
	local 	graphs				1 	// Create graphs
	local 	regressions			1 	// Run regressions and export results

	
		
	
********************************************************************************
*			PART 1:  Set standard settings and install packages				   *
********************************************************************************/
	
	* Install packages
	if `packages' 	{
		ssc install labutil, 	replace
		ssc install ietoolkit, 	replace
		ssc install winsor, 	replace
		ssc install sxpose, 	replace
		ssc install dataout, 	replace
		ssc install estout, 	replace
		ssc install reghdfe, 	replace
	}
	
	ieboilstart, version(13.0)
	`r(version)'
	

	* Set globals
	global fup_rounds 	7			// Number of follow-up rounds
	global tmt_rounds	4			// Number of treatment rounds
	global weekMax	 	146			// Number of weeks with observations
	global monthMax		35			// Number of months with observations
	global sleep		1200		// Delay code for running so it doesn't crash
	
	
		
********************************************************************************
*				PART 2:  Prepare globals and define paths					   *
********************************************************************************	 NOTE: PLEASE USE '/' INSTEAD OF '\' FOR DIRECTORIES FOR COMPATABILITY WITH MACS

	* add your directory below
	 display c(username)  	// 1. copy username below in XX 
							// 2. add path to GitHub folder

	* Set directories 
	* ---------------	
	* Luiza
	if "`c(username)'" == "XX" {
		global github	"ADD FOLDER PATH HERE"
	}
	
	
 	* Subfolder globals
	* -----------------
	gl analysis_do			"$github/Do-files/Analysis" 
	gl masterdata			"$github/Data/Master data sets"
	gl analysis_dt			"$github/Data/Analysis"
	gl output 				"$github/Output"
	gl out_plots			"$output/Raw files/Plots"	
	gl out_regs				"$output/Raw files/Regression results"
	gl out_desc				"$output/Raw files/Descriptive statistics"
	gl out_bal				"$output/Raw files/Balance tests"

	
		
********************************************************************************
*						PART 3:  Run selected sections						   *
********************************************************************************
	
* ------------------------------------------------------------------------------
* 								Attrition test
* ------------------------------------------------------------------------------
*
* 	REQUIRES:	$analysis_dt\hhwater_plotcropgs.dta
*				$masterdata/master_hh.dta
* 	CREATES:	$out_bal/attrition_table.tex
*
* ------------------------------------------------------------------------------
	
	if `attrition'		do "$analysis_do/Attrition test.do"
	
* ------------------------------------------------------------------------------
* 								Balance tests
* ------------------------------------------------------------------------------
*
*	REQUIRES:	$masterdata/master_hh.dta
*				$analysis_dt\hhwater_plotcropgs.dta
*	CREATES:	$out_bal\balance_table.tex
*
* ------------------------------------------------------------------------------
	
	if `balance_tables'	do "$analysis_do/Balance tests.do"
	
* ------------------------------------------------------------------------------
* 							Decriptive statistics
* ------------------------------------------------------------------------------
*
* 	OUTLINE:		TABLE 1 - Sample sizes by round
*					TABLE 2 - Basic Descriptives of Sample Over Study Period
*					TABLE 3 - Distribution of treatment and control assignment			
* 	REQUIRES:		$analysis\hhwater_plotcropgs.dta.dta
*					$masterdata/master_hh.dta
*					$masterdata/plot_tracker.dta
*					$masterdata/master_plot.dta
* 	CREATES:		$out_desc/T1_obs_per_round.tex
*					$out_desc/T2_descriptives.tex
*					$out_desc/T3_takeup.tex
*
* ------------------------------------------------------------------------------
	
	if `descriptives'	do "$analysis_do/Descriptive statistics.do"
	
* ------------------------------------------------------------------------------
* 							Regressions
* ------------------------------------------------------------------------------	
*
*	OUTLINE:		PART 1: Load data
*					PART 2: Treatment effect on share of households with negative water gap
*					PART 3: Treatment effect on yields
* 	REQUIRES:		$analysis\hhwater_plotcropgs.dta
* 	CREATES:		$out_regs/water_gap_neg.tex
*					$out_regs/ln_yield_mtzha_med.tex
*
* ------------------------------------------------------------------------------
					
	if `regressions' 	do "$analysis_do/Regressions.do"
	
* ------------------------------------------------------------------------------
* 							Final plots
* ------------------------------------------------------------------------------	
*
*	REQUIRES:		$analysis\hhwater_plotcropgs.dta
*					$analysis\water_plot_long.dta
*					$analysis_dt\plotweek_watergap.dta
*					$analysis\furrow_week.dta
*	 CREATES:		$out_plots\F1_Conflict_Water.png
*					$out_plots/F2_Pre_treatment_water_gap.png
*					$out_plots\F3_Water_gap_distribution.png
*					$out_plots\F6_Conflict.png
*					$out_plots\F7_Enough_water.png
*					$out_plots/F9_Water_gap.png
*					$out_plots/Water requirements.png
*					$out_plots/corr_avail_req.png
*					$out_plots/Event study.png
*					$out_plots/A4_Water_Precip_Trend.png
*					$out_plots/month_planting_1yr_perc.png
*
* ------------------------------------------------------------------------------

	if `graphs'			do "$analysis_do/Plots.do"
		
			
