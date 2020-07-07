	

	use "hhwater_plotcropgs.dta", clear

	set scheme s2color
	
/*******************************************************************************
	Prepare data
*******************************************************************************/
	
	* Set sample
	drop if d_cult == 0															// drop observations of people that we know didn't plant

	* Identify high and low water users for heterogeneous effects
	preserve
		
		* Identify high users per gs
		keep if round < 5														// We're only interested in the pre-treatment period
		bys 	scheme_id round gs: egen water_gap_median = median(water_gap)	// Median value per scheme, round and gs
		gen 	high = (water_gap > water_gap_median)
		
		* Identify households that are high users
		collapse (mean) high, by(hh_id scheme_id)								// A household is a high user if it's a high user for at least 50% of its plot-crop-gs								
		replace high = high > .5
		
		tempfile high
		save	 `high'
		
	restore
	
	merge m:1 hh_id using `high'
	
	* Create analysis vars
	gen ln_water_gap = ln(water_gap + 1)
	gen ln_water_reqday = ln(water_reqday + 1)
	gen ln_irrigation_gs = ln(irrigation_gs + 1)
	gen ln_water_reqday_tmt = ln_water_reqday * tmt_hh

	* Change labels for tables
	lab def post	  1 "Post-feedback"
	lab def treatment 1 "Individual-feedback"
	lab def high	  1 "High water user"
	
	lab val post post
	lab val tmt_hh treatment
	lab val high high
	
	lab var tmt_hh 				  "Individual feedback treatment"
	lab var ln_water_reqday_tmt   "Individual feedback treatment $\times$ Water requirements"
	lab var ln_water_reqday	      "Water requirements (log mm/day)"


/*******************************************************************************
	Pre-post analysis
*******************************************************************************/
	
// Log water gap ---------------------------------------------------------------
	
	estimates clear
	
	areg ln_water_gap i.post, a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes
	
	areg ln_water_gap tmt_hh##post, a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes
	
	areg ln_water_gap tmt_hh##post##high, a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes
	
	esttab using "prepost_watergap.tex", ///
		nomtitle se ///
		replace label ar2 se(%9.3f) noomit nobase ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		scalars("fe Scheme fixed effects") ///
		addnotes(Notes: Robust standard errors in parentheses, clustered at household level.) ///
		mgroups("Dependent variable: water gap (mm/day)", 						///	Group titles
				pattern(1 0 0) 												/// Which columns are in which group? (1 marks the beginning of a new group
				span prefix(\multicolumn{@span}{c}{) suffix(})   				/// Centralize group titles including both groups
		        erepeat(\cmidrule(lr){@span})) ///
		nonotes

		
// Water availability vs water requirements -------------------------------------		
		
	estimates clear
	
	areg ln_irrigation_gs ln_water_reqday if post == 0, a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes
	
	areg ln_irrigation_gs ln_water_reqday if post == 1, a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes
	
	areg ln_irrigation_gs ln_water_reqday tmt_hh ln_water_reqday_tmt if post == 1, a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes
	
	esttab using "prepost_totalwater.tex", ///
		mtitles("Pre-feedback" "Post-feedback" "Post-feedback") ///
		se ///
		replace label ar2 se(%9.3f) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		scalars("fe Scheme fixed effects") ///
		addnotes(Notes: Robust standard errors in parentheses, clustered at household level.) ///
		mgroups("Dependent variable: water availability (log mm/day)", 						///	Group titles
				pattern(1 0 0) 												/// Which columns are in which group? (1 marks the beginning of a new group
				span prefix(\multicolumn{@span}{c}{) suffix(})   				/// Centralize group titles including both groups
		        erepeat(\cmidrule(lr){@span})) 	
		
/*******************************************************************************
	Water gap figure: pre-post
*******************************************************************************/

	tw 	(kdensity water_gap if post == 0, lpattern(dash) color(gs8)) ///
		(kdensity water_gap if post == 1 & tmt_hh == 1, color(edkblue)) ///
		(kdensity water_gap if post == 1 & tmt_hh == 0, color(eltblue)), ///
		graphregion(color(white)) bgcolor(white) ///
		legend(order(1 "Pre-feedback" ///
					 2 "Post-feedback (individual)" ///
					 3 "Post-feedback (general)")) ///
		ytitle(Density) ///
		xtitle(Water gap (mm/day)) ///
		note("Notes: Graph shows kernel density using Epanechnikov kernal with optimal bandwidth selection." ///
			  "Water gap is defined as ln(irrigation + rain) - ln(water requirements).")
		
		
	gr export "watergapprepost.png", width(5000) replace

	
	
/*******************************************************************************
	Self-reported irrigation
*******************************************************************************/	
		
// gs3/gs1 ratio ---------------------------------------------------------------	
	
	estimates clear
	
	areg irrigation_self_ratio_win i.post , a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes

	areg irrigation_self_ratio_win post##tmt_hh, a(scheme_id) cluster(hh_id)
	eststo
	estadd local fe Yes

	esttab using "irrigation_self_ratio.tex", ///
		nomtitle replace label ar2 se(%9.3f) nonote ///
		star(* 0.10 ** 0.05 *** 0.01) nobase noomit ///
		scalars("fe Scheme fixed effects") ///
		addnotes(Notes: Robust standard errors in parentheses, clustered at household level.) ///
		mgroups("Dependent variable: self-reported irrigation ratio (GS3/GS1)", 						///	Group titles
				pattern(1 0 ) 												/// Which columns are in which group? (1 marks the beginning of a new group
				span prefix(\multicolumn{@span}{c}{) suffix(})   				/// Centralize group titles including both groups
		        erepeat(\cmidrule(lr){@span})) 

// Complete version ------------------------------------------------------------	

	estimates clear
	forvalues gs = 1/4 {
	
		areg irrigation_self post##tmt_hh if gs == `gs', a(scheme_id) cluster(hh_id)
		eststo
		estadd local fe Yes
	
	}
	
	esttab using "irrigation_self.tex", ///
		mtitles("Growth stage 1" "Growth stage 2" "Growth stage 3" "Growth stage 4") se ///
		replace label ar2 se(%9.3f) ///
		star(* 0.10 ** 0.05 *** 0.01) nobase noomit nonote ///
		scalars("fe Scheme fixed effects") ///
		addnotes(Notes: Robust standard errors in parentheses, clustered at household level.) ///
		mgroups("Dependent variable: self-reported irrigation", 						///	Group titles
				pattern(1 0 0 0) 												/// Which columns are in which group? (1 marks the beginning of a new group
				span prefix(\multicolumn{@span}{c}{) suffix(})   				/// Centralize group titles including both groups
		        erepeat(\cmidrule(lr){@span})) 
				
		
// Only pre and post ------------------------------------------------------------	

	estimates clear
	forvalues gs = 1/4 {
	
		areg irrigation_self i.post if gs == `gs', a(scheme_id) cluster(hh_id)
		eststo
		estadd local fe Yes
	
	}
	
	esttab using "irrigation_self_notmt.tex", ///
		mtitles("Growth stage 1" "Growth stage 2" "Growth stage 3" "Growth stage 4") se ///
		replace label ar2 se(%9.3f) ///
		star(* 0.10 ** 0.05 *** 0.01) nobase noomit nonote ///
		scalars("fe Scheme fixed effects") ///
		addnotes(Notes: Robust standard errors in parentheses, clustered at household level.) ///
		mgroups("Dependent variable: self-reported irrigation", 						///	Group titles
				pattern(1 0 0 0) 												/// Which columns are in which group? (1 marks the beginning of a new group
				span prefix(\multicolumn{@span}{c}{) suffix(})   				/// Centralize group titles including both groups
		        erepeat(\cmidrule(lr){@span})) 
				
/*******************************************************************************
	Quantile graph
*******************************************************************************/

	use "hhwater_plotcropgs.dta", clear

	gen ln_water_gap = ln(water_gap + 1)
	keep if post == 1
	
	forvalues i = 5(5)100 {
		
		local j = `i'/100
		
		xi: qreg ln_water_gap tmt_hh i.scheme_id, q(`j')

		mat result 	 = r(table)
		
		gen beta_`i' = result[1,1]
		gen lb_`i' 	 = result[5,1]
		gen ub_`i' 	 = result[6,1]
		
	}

	collapse beta_* ub* lb*
	gen id = 1
	reshape long beta_ ub_ lb_, i(id) j(i)

	twoway  rcap lb_ ub_ i, fcolor(gs11) lcolor(gs11)  ///
				  || scatter beta_ i, ///
				  ytitle("Q-reg coeff on ind. inf. treat in post period" "(in ln(mm/day))") title(QREG - Within Bandwidth) ///
				  xtitle("Percentile") legend(order(2 "Quant. Reg. Coefficient" 1 "90% CI")) ///
				  bgcolor(white) graphregion(color(white)) 
	
	graph export "qreg_bw.png", replace as(png)

***************************************************************** End of do-file
