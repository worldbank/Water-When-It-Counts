/* *************************************************************************** *
*						Mozambique PRIORRI									   *												   
*																 			   *
*  PURPOSE:  			Run analysis regressions							   *		  
*  WRITEN BY:  			Luiza Andrade [lcardosodeandrad@worldbank.org]		   *
*  Last time modified:  Jan 2018											   *
*																			   *
********************************************************************************


	** OUTLINE:		PART 1: Load data
					PART 2: Treatment effect on share of households with negative water gap
					PART 3: Treatment effect on yields
				
	** REQUIRES:	$analysis\hhwater_plotcropgs.dta
	
	** CREATES:		$out_regs/water_gap_neg.tex
					$out_regs/ln_yield_mtzha_med.tex
					
				
	** NOTES:		
	
	
********************************************************************************
*							PART 1: Load data
*******************************************************************************/

	* Load data
	use 	"$analysis_dt\hhwater_plotcropgs.dta", clear
	
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
	
	* Create heterogeneity variables
	foreach varAux of varlist post tmt_hh tmt_hh_post {
		gen `varAux'_high = `varAux'*high	
	}
	
	* Label variables
	lab var	tmt_hh						"Individual feedback"
	lab var	tmt_hh_post					"Individual feedback * post"
	lab var	tmt_hh_high					"Individual feedback * High water gap"
	lab var	tmt_hh_post_high			"Individual feedback * Post * High water gap"
	lab var high						"High water gap"
	lab var	post						"Post"
	lab var	post_high					"Post * High water gap"
	lab var water_gap_neg				"Water gap is negative"
	
	
********************************************************************************
*	PART 2: Treatment effect on share of households with negative water gap
********************************************************************************	
	
	eststo clear 
	
	* First: simple DID
	reghdfe water_gap_neg 	tmt_hh post tmt_hh_post, ///
							vce(cluster hh_id) absorb(pair moyplant)

	eststo
	estadd	local pair 		"Yes"
	estadd	local month 	"Yes"
	
	* Second: with heterogeneity
	reghdfe water_gap_neg 	tmt_hh post tmt_hh_post ///
							high tmt_hh_high post_high tmt_hh_post_high, ///
							absorb(pair moyplant) ///
							vce(cluster hh_id)
	eststo
	estadd	local pair 		"Yes"
	estadd	local month 	"Yes"	
	
	* Export
	esttab using 	"$out_regs/delete_me.tex", ///
					replace label ar2 se(%9.3f) ///
					scalars("pair Randomization pairs fixed-effects" "month Month of planting fixed-effects") ///
					noconstant star(* 0.10 ** 0.05 *** 0.01) ///
					addnotes(Notes: Observations at are at household-round-plot-crop-growth stage level. Sample is restricted to plots that were cultivated. Standard errors are clustered by household to account for autocorrelation. \sym{*} \(p<0.1\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)) nonotes nomtitles ///
					order(post tmt_hh post tmt_hh_post high post_high tmt_hh_high tmt_hh_post_high)
	
	sleep $sleep				
	filefilter 	"$out_regs/delete_me.tex" "$out_regs/water_gap_neg.tex", ///				
				from("{l}") to("{p{.9\BStextwidth}}") replace
	erase 		"$out_regs/delete_me.tex"
	
	
********************************************************************************
*						PART 3: Treatment effect on yields
********************************************************************************		
	
* ------------------------------------------------------------------------------
* 							Prepare dataset
* ------------------------------------------------------------------------------

	* The data set is a hh-plot-crop-gs level, but we want to report
	* yield per households, so we'll add revenue and cultivated areas
	* across all observations for the same household and round
	drop if inlist(moyharv,10)														// don't have obs before and after treatment
	
	* Yield is reported only once per crop, but is repeated 4 times in this
	* dataset, as it's plot-crop-gs level. So we'll keep only one observation
	* per crop for these variables
	replace yield_mtz_med = . 	if gs != 1 						
	replace areacult = . 		if gs != 1 

	collapse	tmt_hh tmt_hh_post pair ///
				(sum) yield_mtz_med areacult ///
				(max) water_gap_neg ///
				(mean) water_gap, ///
				by (hh_id post round scheme_id plot_id)
				
	sort hh_id plot_id round
	
	replace water_gap = . 	  if water_gap_neg == . 						// missing water gap turns zero when we take the average, even though it should be missing
	replace water_gap_neg = . if post == 1									// we only want to look at pre-treatment observations for heterogeneity
	
	* Create heterogeneity variables
	gen av_negative = (water_gap < 0) if post == 0 & water_gap != .
	bys hh_id plot_id: egen av_negative_pre = max(av_negative)
	
	foreach varAux of varlist post tmt_hh tmt_hh_post {
		gen `varAux'_av_negative_pre = `varAux'*av_negative_pre		
	}
	
	* Create of yield
	gen ln_yield_mtzha_med = log((yield_mtz_med/areacult) + 1)
	
	* Label variables
	lab var tmt_hh							"Individual feedback"
	lab var post							"Post"
	lab var av_negative_pre					"Average pre-feedback water gap is negative"
	lab var tmt_hh_post						"Individual feedback * Post"
	lab var tmt_hh_av_negative_pre			"Individual feedback * Average pre-feedback water gap is negative"	
	lab var post_av_negative_pre			"Post * Average pre-feedback water gap is negative"
	lab var tmt_hh_post_av_negative_pre		"Individual feedback * Post * Average pre-feedback water gap is negative"
			

* ------------------------------------------------------------------------------
* 								Run regressions
* ------------------------------------------------------------------------------

	estimates clear
	
	* Without heterogeneity variables
	qui reg ln_yield_mtzha_med 	tmt_hh post tmt_hh_post ///
								i.pair i.round, ///
								vce(cluster hh_id)
	eststo
	estadd	local pair 		"Yes"
	estadd	local round 	"Yes"
	
	* With heterogeneity variables							
	qui reg ln_yield_mtzha_med 	tmt_hh post av_negative_pre ///
								tmt_hh_post post_av_negative_pre tmt_hh_av_negative_pre ///
								tmt_hh_post_av_negative_pre ///
								i.pair i.round, vce(cluster hh_id)
	
	eststo
	estadd	local pair 		"Yes"
	estadd	local round 	"Yes"
	
* ------------------------------------------------------------------------------
* 								Export results
* ------------------------------------------------------------------------------
	
	esttab using 	"$out_regs/delete_me.tex", ///
					replace label ar2 se(%9.3f) ///
					noconstant star(* 0.10 ** 0.05 *** 0.01) ///
					scalars("pair Randomization pairs fixed-effects" "round Round fixed-effects") ///
					addnotes(Notes: Observations at are at household-round-plot level. Sample is restricted to plots that were cultivated. Standard errors are clustered by household. \sym{*} \(p<0.1\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)) nonotes nomtitles ///
					order(tmt_hh post tmt_hh_post av_negative_pre tmt_hh_av_negative_pre post_av_negative_pre tmt_hh_post_av_negative_pre) ///
					keep(tmt_hh post av_negative_pre tmt_hh_post tmt_hh_av_negative_pre post_av_negative_pre tmt_hh_post_av_negative_pre)
	
	sleep $sleep
	filefilter 	"$out_regs/delete_me.tex" "$out_regs/ln_yield_mtzha_med.tex", 	///				
				from("{l}") to("{p{.9\BStextwidth}}") replace
	erase 		"$out_regs/delete_me.tex"
		
