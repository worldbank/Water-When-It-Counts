	

	use "$analysis_dt\hhwater_plotcropgs.dta", clear

	
	gen ln_water_gap = ln(water_gap)
	gen ln_water_reqday = ln(water_reqday)
	gen ln_water_reqday_tmt = ln_water_reqday * tmt_hh
	
	* Restrict sample
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
	
	* Merge heterogeneity var to whole period data set
	merge m:1 hh_id using `high'
	
	areg ln_water_gap post, a(scheme_id)
	eststo
	
	areg ln_water_gap tmt_hh##post, a(scheme_id)
	eststo
	
	areg ln_water_gap tmt_hh##post##high, a(scheme_id)
	eststo
	
	
	tw (kdensity water_gap if post == 0) (kdensity water_gap if post == 1 & tmt_hh == 1) (kdensity water_gap if post == 1 & tmt_hh == 0)
		
	areg ln_totwater_gs ln_water_reqday if post == 0, a(scheme_id)
	areg ln_totwater_gs ln_water_reqday if post == 1, a(scheme_id)
	areg ln_totwater_gs ln_water_reqday tmt_hh ln_water_reqday_tmt if post == 1, a(scheme_id)
