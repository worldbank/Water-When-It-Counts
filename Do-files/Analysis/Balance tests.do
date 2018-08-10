/* *************************************************************************** *
*						Mozambique PRIORRI									   *												   
*																 			   *
*  PURPOSE:  			Run balance tests									   *		  
*  WRITEN BY:  			Luiza Andrade [lcardosodeandrad@worldbank.org]		   *
*  Last time modified:  Jan 2018											   *
*																			   *
********************************************************************************

	
	** OUTLINE:		PART 1: Load data
					PART 2: Create variables of interest
					PART 3: Label variables
					PART 4: Export balance table
				
	** REQUIRES:	$masterdata/master_hh.dta
					$analysis_dt\hhwater_plotcropgs.dta
	
	** CREATES:		$output\Raw files\Balance tests\balance_table.tex
				
	** NOTES:		
	
	
********************************************************************************
*							PART 1: Load data
*******************************************************************************/

	* Load survey data		
	* ----------------
	use 	"$analysis_dt\hhwater_plotcropgs.dta", clear
	
	* Merge to master
	* ---------------
	merge m:1 hh_id using "$masterdata/master_hh.dta", assert(2 3) nogen keep (3)
	
	* Keep round 2 if available, and round 1 if 2 is not available
	* ------------------------------------------------------------
	gen 	keep = (round == 2 & d_surveyed_fup2 == 1) 								// when randomization was done
	replace keep = 1 if round == 1 & d_surveyed_fup1 == 1 & d_surveyed_fup2 == 0	// not surveyed in round 2
	keep if keep == 1

********************************************************************************
*						PART 2: Create variables of interest
********************************************************************************

	* Create conflict and enough water varibles
	* -----------------------------------------
	foreach varAux in conflict water {
	
		egen 		sum_`varAux' = rowtotal(d_`varAux'_mth*)
		egen		obs_`varAux' = rownonmiss(d_`varAux'_mth*)
		
		bys hh_id plot_id: 	gen pct_`varAux'_plot = sum_`varAux'/obs_`varAux' if _n == 1
		bys hh_id: 			gen pct_`varAux' = sum_`varAux'/obs_`varAux' if _n == 1 		// observations are repeated, we want to keep only one per household

	}
	
	* Keep only one observation per household
	bys hh_id: gen hh1 = _n
	bys hh_id: egen pct_water_hh = mean(pct_water_plot)
	bys hh_id: replace pct_water_hh = . if hh1 > 1
	replace pct_water_hh = . if d_surveyed_hh == 0
	
	* Calculate cultivated share of plots
	* -----------------------------------
	replace areacult = 0 		if d_cult == 0
	bys hh_id plot_id crop_id: 	gen crop1 = _n
	bys hh_id plot_id crop_id: 	gen shareplant = areacult/area_ha if crop1 == 1	// observations are repeated 4 times, we want to keep only one
	
	* Identify hhs cultivating more than one crop during round 2
	bys hh_id plot_id:  		gen count = _N
	gen flag_mult = 1 			if count == 12									// all 4 hhs cultivating 3 crops cultivated them all at the same time
	bys hh_id plot_id:			egen mthpharv1 = min(mthharvest_adj) if count == 8
	bys hh_id plot_id:			egen mthplant2 = min(mthplant_adj)	 if count == 8
	replace flag_mult = 1		if count == 8 & mthplant2 > mthpharv1			// hhs cultivating 2 crops: flag if they were cultivated at the same time
	
	* If hh was cultivating more than one crop, sum cultivated areas
	bys hh_id plot_id crop_id:	egen shareplant2 = total(shareplant) ///		   
									 if flag_mult == 1
	replace shareplant 			= shareplant2 if shareplant2 != .
	
	* Correct for measurement errors: can never plant more
	replace shareplant = 1 if shareplant > 1 & shareplant != .
		
	* Get average cultivated area and plot area per hh							// otherwise, we're giving more weight to plots that were cultivated by more than one household
	* ------------------------------------------------
	bys hh_id: egen share_plant 	= mean(shareplant)
	bys hh_id: egen area 			= mean(area_ha)
	
	* Keep only one observations per household
	bys hh_id: replace share_plant = . 	if (hh1 > 1 | d_surveyed_plot == 0)
	bys hh_id: replace area = . 		if hh1 > 1
			
	bys hh_id plot_id crop_id: replace yield_mtz_med = . 	 if crop1 > 1		// observations are repeated 4 times, we want to keep only one
	bys hh_id plot_id crop_id: replace areacult = .  		 if crop1 > 1
	
	* Average yield per household
	* ---------------------------
	bys hh_id: egen revenue = total(yield_mtz_med)
	bys hh_id: egen areac = total(areacult)
	gen yield = revenue/(areac*1000)
	
	* Keep only one observation per household
	bys hh_id: replace yield = .  		 if hh1 > 1
	
********************************************************************************
*							PART 3: Label variables
********************************************************************************

	lab var	area					"Plot area (ha)"
	lab var	share_plant				"Average share of plot area that was cultivated"
	lab var	pct_conflict			"Share of months household reports there was conflict"
	lab var	pct_water_hh			"Share of months household reports there was enough water"
	lab var yield					"Average yield per hectare (thousands of Meticais)"
	lab var	water_gap_neg			"Share of observations with negative water gap"
	lab var ln_totwater_gs			"Total water availability (log mm/day)"
	lab var ln_rain_gs				"Average precipitation (log mm/day)"
	lab var water_gap				"Water gap (log mm/day)"
	lab var water_gap_abs			"Absolute water gap (log mm/day)"
	
********************************************************************************
*						PART 4: Export balance table
********************************************************************************

	iebaltab 	area share_plant pct_conflict pct_water_hh yield ///
				ln_totwater_gs ln_rain_gs ///
				water_gap water_gap_neg water_gap_abs, ///
				grpvar(tmt_hh) grplabels(1 Individual feedback @ 0 General feedback) ///
				covariates(pair) vce(cluster hh_id) ///
				rowvarlabels texnotewidth(1.55) ///
				notecombine tblnote(Data refers to round 2 when available, as feedback was randomized based on data from this round, and round 1 when the household wasn't surveyed on round 2. Seven households did not cultivate any crops during this round's period. For these households, the average share of plot area cultivated is zero, and yields are missing. The number of observations for water gap is different from the number of observations for water availability due to lack of data on water requirements for onion.) ///
				savetex("$out_bal\delete_me1.tex") replace

********************************************************************************
*						PART 5: Calculate F-test
********************************************************************************
	
	reg tmt_hh share_plant pct_conflict pct_water_hh yield i.pair, vce(cluster hh_id)
	testparm share_plant pct_conflict pct_water_hh yield
	if round(r(F),0.01) == 1.46	{ 
		local test_F_hh 1.46
	}
	else {
		di as error "Fix F-stat for households vars"
		error
	}
	
	reg tmt_hh ln_totwater_gs ln_rain_gs water_gap water_gap_neg water_gap_abs i.pair, vce(cluster hh_id)
	testparm ln_totwater_gs ln_rain_gs water_gap water_gap_neg water_gap_abs
	if round(r(F),0.01) == 2.89 {
		local test_F_gs 2.89**
	}
	else {
		di as error "Fix F-stat for gs vars"
		error
	}
	
********************************************************************************
*						PART 6: Adjust format
********************************************************************************
		
	filefilter 	"$out_bal/delete_me1.tex" "$out_bal/delete_me2.tex", 	///		
				from("Plot area (ha)") ///
				to("\BSmulticolumn{1}{l}{\BStextit{Listing}} &&&& \BS\BS \BS\BS[-1.8ex] \BSqquad Plot area (ha)") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me2.tex" "$out_bal/delete_me1.tex", 	///		
				from("Share of observations with negative water gap") ///
				to("\BSqquad Share of observations with negative water gap") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me1.tex" "$out_bal/delete_me2.tex", 	///		
				from("Share of months household reports there was conflic") ///
				to("\BSqquad Share of months household reports there was conflic") replace
					
	sleep $sleep
	filefilter 	"$out_bal/delete_me2.tex" "$out_bal/delete_me1.tex", 	///		
				from("Share of months household reports there was enough water") ///
				to("\BSqquad Share of months household reports there was enough water") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me1.tex" "$out_bal/delete_me2.tex", 	///		
				from("Average yield per hectare (thousands of Meticais)") ///
				to("\BSqquad Average yield per hectare (thousands of Meticais)") replace
					
	sleep $sleep
	filefilter 	"$out_bal/delete_me2.tex" "$out_bal/delete_me1.tex", 	///		
				from("Standard errors are clustered at variable hh\BS_id") ///
				to("Standard errors are clustered at the household level") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me1.tex" "$out_bal/delete_me2.tex", 	///		
				from("Total water availability") ///
				to("\BSmulticolumn{1}{l}{F-test of joint significance (F-stat)} &&&&&`test_F_hh' \BS\BS \BShline \BS\BS[-1.8ex] \BSmulticolumn{1}{l}{\BStextit{ Household-plot-crop-growth stage observations}} &&&& \BS\BS \BS\BS[-1.8ex] \BSqquad Total water availability") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me2.tex" "$out_bal/delete_me1.tex", 	///		
				from("Average precipitation") ///
				to("\BSqquad Mean precipitation in that GS") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me1.tex" "$out_bal/delete_me2.tex", 	///		
				from("Water gap") ///
				to("\BSqquad Water gap") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me2.tex" "$out_bal/delete_me1.tex", 	///		
				from("Absolute water gap") ///
				to("\BSqquad Absolute water gap") replace
					
	sleep $sleep			
	filefilter 	"$out_bal/delete_me1.tex" "$out_bal/delete_me2.tex", 	///		
				from("\BS\BS (0.087) \BSend{tabular} &    -0.021 \BSrule{0pt}{3ex}\BS\BS") ///
				to("\BS\BS (0.087) \BSend{tabular} &    -0.021 \BSrule{0pt}{3ex}\BS\BS \BSmulticolumn{1}{l}{F-test of joint significance (F-stat)} &&&&&`test_F_gs' \BS\BS") replace
					
	sleep $sleep
	filefilter 	"$out_bal/delete_me2.tex" "$out_bal/balance_table.tex", 	///		
				from("Average share of plot area that was cultivated") ///
				to("\BShline \BS\BS[-1.8ex] \BSmulticolumn{1}{l}{\BStextit{Household average across plots}} &&&& \BS\BS \BS\BS[-1.8ex] \BSqquad Average share of plot area that was cultivated") replace

	erase "$out_bal/delete_me1.tex"
	erase "$out_bal/delete_me2.tex"
