/* *************************************************************************** *
*						Mozambique PRIORRI									   *												   
*																 			   *
*  PURPOSE:  			Create final plots									   *		  
*  WRITEN BY:  			Luiza Andrade [lcardosodeandrad@worldbank.org]		   *
*  Last time modified:  Jan 2018											   *
*																			   *
********************************************************************************


	** OUTLINE:		PART 1: Household level plots
							Water scarcity and conflict - descriptive
							Share of households that reported conflict over water
							Water scarcity and conflict - treatment effect
							Water requirements
					PART 2:	HH-plot-crop-gs plots
							Pre-treatment Distribution of Water Gap
							Water Gap Per Growth Stage
					PART 4: Distribution of water gap per scheme
					PART 5: Relationship between requirements and availability
					PART 6: Share of plots with negative water gap by week
					PART 7: Water availability and precipitation before treatment
					PART 9: Month of planting
							
				
	** REQUIRES:	$analysis\hhwater_plotcropgs.dta
					$analysis\water_plot_long.dta
					$analysis_dt\plotweek_watergap.dta
					$analysis\furrow_week.dta
	
	** CREATES:		$out_plots\F1_Conflict_Water.png
					$out_plots/F2_Pre_treatment_water_gap.png
					$out_plots\F3_Water_gap_distribution.png
					$out_plots\F6_Conflict.png
					$out_plots\F7_Enough_water.png
					$out_plots/F9_Water_gap.png
					$out_plots/Water requirements.png
					$out_plots/corr_avail_req.png
					$out_plots/Event study.png
					$out_plots/A4_Water_Precip_Trend.png
					$out_plots/month_planting_1yr_perc.png
					
	** NOTES:		
	
		
********************************************************************************
*					PART 1: Household level plots
*******************************************************************************/
	
	graph drop _all
	
	use 	"$analysis_dt\hhwater_plotcropgs.dta", clear
			
* ------------------------------------------------------------------------------
*				Water scarcity and conflict - descriptive
* ------------------------------------------------------------------------------

	* Process data: make it HH-month level
	* ------------------------------------
	
	preserve
		
		* Collapse to HH level
		keep 		hh_id plot_id round crop_id gs d_conflict* d_water*  post
		collapse	post (max)  d_conflict* d_water*, by(hh_id round)			// hh-plot-crop-gs -> hh-round
		reshape 	long d_conflict_mth d_water_mth, i(hh_id round) j(month)	// hh-round -> hh-round-month
		drop if 	d_conflict_mth == .  & d_water_mth == .
			
		* Label month variable
		lab def		month	7  "Jul/15" 8  "Aug/15" 9  "Sep/15" 10 "Oct/15" ///
							11 "Nov/15" 12 "Dec/15" 13 "Jan/16" 14 "Feb/16" ///
							15 "Mar/16" 16 "Apr/16" 17 "May/16" 18 "Jun/16" ///
							19 "Jul/16" 20 "Aug/16" 21 "Sep/16" 22 "Oct/16" ///
							23 "Nov/16"
		lab val		month	month
		
		* Create interaction variables
		foreach varAux of varlist d_conflict_mth d_water_mth {
			replace 	`varAux' = `varAux'*100
			gen			`varAux'_post = `varAux'*post  	if post == 1
			replace		`varAux'= .  					if post == 1
		}
		
		* Calculate coefficient to be reported
		reg 	d_conflict_mth d_water_mth if post == 0
		local 	beta = round(_b[d_water_mth],.001)
		local 	r2 	= round(e(r2),.001)

	
		* Create graph
		gr	bar 	d_conflict_mth d_water_mth if post == 0, ///
			over	(month, label (angle(45))) ///
			blabel	(total, format(%9.1f) size(vsmall)) ///
			legend	(order (1 "Reported conflict over water" 2 "Reported having enough water") ///
					 cols(1)) ///
			ytitle	(Percentage of households) ///
			bgcolor (white) graphregion(color(white)) ///
			text	(100 92 "Regression of conflict" "on enough water" "Slope = `beta'" "R{superscript:2} = `r2'", ///
					 orient(horizontal) size(vsmall) justification(center) fcolor(white) box margin(small))
			
		* Export graph
		gr export	"$out_plots\F1_Conflict_Water.png", width(5000) replace
		
			
* ------------------------------------------------------------------------------
*			Share of households that reported conflict over water
* ------------------------------------------------------------------------------
		
		* Create calendar month variable										// Month variable is not counted in months since Jan 15
		gen 	 	cal_month = month 		if month <= 12
		replace 	cal_month = month - 12	if month > 12 & month <=24
		replace 	cal_month = month - 24	if month > 24 & month <=36
		
		* Label calendar month
		lab def		cal_month	1 "Jan" 2 "Feb" 3  "Mar" 4  "Apr" 5 "May" 6 "Jun" 7 "Jul" ///
								8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
		lab val		cal_month	cal_month
		
		* Create graph
		gr	bar 	d_conflict_mth d_conflict_mth_post, over(cal_month) ///
			blabel	(total, format(%9.1f) size(vsmall)) ///
			legend	(order (1 "Pre-feedback" 2 "Post-feedback")) ///
			ytitle	(Percentage of households) ///
			bgcolor (white) graphregion(color(white))
		
		* Export graph
		gr export	"$out_plots\F6_Conflict.png", width(5000) replace
		
* ------------------------------------------------------------------------------
*				Water scarcity and conflict - treatment effect
* ------------------------------------------------------------------------------

		* Create graph
		gr	bar 		d_water_mth d_water_mth_post, over(cal_month) ///
			blabel		(total, format(%9.0f) size(vsmall)) ///
			legend		(order (1 "Pre-feedback" 2 "Post-feedback")) ///
			ytitle		(Percentage of households) ///
			bgcolor 	(white) ///
			graphregion	(color(white))
		
		* Export graph
		gr export	"$out_plots\F7_Enough_water.png", width(5000) replace

	restore
	
*-------------------------------------------------------------------------------
*							Water requirements
*-------------------------------------------------------------------------------

	preserve
			
		* We'll only report water requirement for the most common crops
		gen 	req_maize =	water_reqday 		if crop_id == 35
		gen 	req_cabbage = water_reqday 		if crop_id == 18
		gen 	req_baby_corn = water_reqday 	if crop_id == 8
		
		* Collapse per growth stage for all pre-treatment period
		collapse	(mean) irrigation_gs req_* if round < 5, by(gs)
		
		* Label variables
		lab var irrigation_gs 	"Av. water availability"
		lab var req_maize 		"Maize"
		lab var req_cabbage 	"Cabbage"
		lab var req_baby_corn	"Baby corn"
		lab var gs				"Growth stage"
		
		* Create graph
		twoway 	(bar irrigation_gs gs, color(gs13) barwidth(.9)) ///
				(line req_maize gs, color(cranberry) lwidth(.8)) ///
				(line req_cabbage gs, color(eltblue) lwidth(.8)) ///
				(line req_baby_corn gs, color(navy) lwidth(.8)), ///
				bgcolor(white) graphregion(color(white)) ///
				ytitle(mm/day) 
				
		* Export graph
		gr export	"$out_plots/Water requirements.png", width(5000) replace
	
	restore
	
********************************************************************************
*							PART 2:	HH-plot-crop-gs data
********************************************************************************
	
	* Restrict sample
	drop if d_cult == 0															// drop observations of people that didn't plant
	
* ------------------------------------------------------------------------------
*						Pre-treatment Distribution of Water Gap
* ------------------------------------------------------------------------------	

	* Loop through scheme
	forvalues scheme = 10(10)30 {
		
		if `scheme' == 10 local schemeName Scheme 1
		if `scheme' == 20 local schemeName Scheme 2
		if `scheme' == 30 local schemeName Scheme 3 
		
		* Plot
		twoway 	(kdensity water_gap if gs == 1 & post == 0 & scheme_id == `scheme', lcolor(eltblue) lwidth(.6)) || ///
				(kdensity water_gap if gs == 2 & post == 0 & scheme_id == `scheme', lcolor(emidblue) lwidth(.6)) || ///
				(kdensity water_gap if gs == 3 & post == 0 & scheme_id == `scheme', lcolor(edkblue) lwidth(.6)) || ///
				(kdensity water_gap if gs == 4 & post == 0 & scheme_id == `scheme', lcolor(navy) lwidth(.6)) , ///
				legend(label (1 "1") label (2 "2") label (3 "3") label (4 "4") cols(4)) ///
				xtitle("mm/day (log)") ytitle("Density") xline(0) title(`schemeName') ///
				bgcolor (white) graphregion(color(white)) ///
				name(Pre`scheme')
						
	}
	
	* Pooling schemes
	twoway 	(kdensity water_gap if gs == 1 & post == 0, lcolor(eltblue) lwidth(.6)) || ///
			(kdensity water_gap if gs == 2 & post == 0, lcolor(emidblue) lwidth(.6)) || ///
			(kdensity water_gap if gs == 3 & post == 0, lcolor(edkblue) lwidth(.6)) || ///
			(kdensity water_gap if gs == 4 & post == 0, lcolor(navy) lwidth(.6)) , ///
			legend(label (1 "1") label (2 "2") label (3 "3") label (4 "4") cols(4)) ///
			xtitle("mm/day (log)") ytitle("Density") xline(0) title(Schemes pooles) ///
			bgcolor (white) graphregion(color(white)) ///
			name(PreAll)
			
	* Combine graphs
	gr combine 	PreAll Pre10 Pre20 Pre30, ///
				cols(2) ycommon xcommon iscale(.4) ///
				graphregion(color(white))
				
	* Save
	gr export	"$out_plots/F2_Pre_treatment_water_gap.png", width(5000) replace
	gr drop		_all

	
* ------------------------------------------------------------------------------
*						Water Gap Per Growth Stage
* ------------------------------------------------------------------------------

	* Create plot per treatment and period interaction
	forvalues tmt = 0/1 {
	
		if `tmt' == 0 local tmtName General Feedback
		if `tmt' == 1 local tmtName Individual Feedback
	
		* Loop through period
		forvalues post = 0/1 {
		
			if `post' == 0 	local tmtPeriod Pre
			if `post' == 1 local tmtPeriod Post

			* Plot
			twoway 	(kdensity water_gap if gs == 1 & post == `post' & tmt_hh == `tmt', lcolor(eltblue) lwidth(.6)) || ///
					(kdensity water_gap if gs == 2 & post == `post' & tmt_hh == `tmt', lcolor(emidblue) lwidth(.6)) || ///
					(kdensity water_gap if gs == 3 & post == `post' & tmt_hh == `tmt', lcolor(edkblue) lwidth(.6)) || ///
					(kdensity water_gap if gs == 4 & post == `post' & tmt_hh == `tmt', lcolor(navy) lwidth(.6)) , ///
					legend(label (1 "1") label (2 "2") label (3 "3") label (4 "4") cols(4)) ///
					xtitle("mm/day (log)") ytitle("Density") xline(0) title("`tmtName': `tmtPeriod'") ///
					bgcolor (white) graphregion(color(white)) ///
					name(`tmtPeriod'`tmt')
		}				
	}
	
	* Merge plots into 1
	gr combine 	Pre0 Pre1 Post0 Post1, ///
				cols(2) ycommon xcommon iscale(.4) ///
				graphregion(color(white))
				
	* Save
	gr export	"$out_plots/F9_Water_gap.png", width(5000) replace
	gr drop		_all
	

********************************************************************************
*					PART 4: Distribution of water gap per scheme
********************************************************************************

* ------------------------------------------------------------------------------
* 				Calculate share of plots with negative water gap
* ------------------------------------------------------------------------------

	* Load data set
	use 	"$analysis_dt\plotweek_watergap.dta",	clear
	
	* Collapse per week and scheme
	collapse (count) plot_id (sum) water_gap_neg, by(scheme_id week)
	
	* Calculate share
	gen share_plot_def = water_gap_neg/plot_id
	
	* Save tempfile
	tempfile plots
	save	 `plots'
	
* ------------------------------------------------------------------------------
* 							Get furrow level data
* ------------------------------------------------------------------------------

	* Load data set
	use "$analysis_dt\furrow_week.dta",	clear

	* Collapse to scheme level
	collapse post 	(sum) totwater water_reqday ///
					(count) count_totwater = totwater count_water_reqday = water_reqday, ///
					by(scheme_id week)
					
	foreach varAux of varlist water_reqday totwater {
		replace `varAux' = . if count_`varAux' == 0								// Make sure collapse doesn't turn missings into zero
	}
	
	* Create water gap
	foreach varAux in totwater water_reqday {
		gen ln_`varAux' = ln((`varAux') + 1)		
	}
	
	gen water_gap = ln_totwater - ln_water_reqday
	
* ------------------------------------------------------------------------------
* 							Merge and restrict sample
* ------------------------------------------------------------------------------
	
	* Merge to plot data
	merge 1:1 scheme_id week using `plots', keep(3)	
	
	* Restrict sample
	drop if post == 1 																// only pre-treatment
	drop if totwater == .															// missing water

* ------------------------------------------------------------------------------
* 							Create graph per scheme
* ------------------------------------------------------------------------------

	forvalues scheme = 10(10)30 {
		
		if `scheme' == 10 local schemeName Scheme 1
		if `scheme' == 20 local schemeName Scheme 2
		if `scheme' == 30 local schemeName Scheme 3
		
		twoway 	(bar share_plot_def week if scheme_id == `scheme', bcolor(eltblue) ytitle("Share of plots")) ///
				(line water_gap week if scheme_id == `scheme', lcolor(edkblue) lwidth(0.5) yaxis(2)), ///
				graphregion(color(white)) bgcolor(white) ///
				ytitle("Daily volume (mm/hectare)", axis(2)) ///
				legend(label(1 "Share of plots in deficit") label(2 "Total scheme daily" "water gap")) ///
				xlabel(27 "Jul 15" 54 "Jan 16" 80 "Jul 16" 106 "Jan 17") ///
				xtitle("") ///
				title(`schemeName') ///
				name(scheme`scheme')
	}

* ------------------------------------------------------------------------------
* 						Create graph for pooled schemes
* ------------------------------------------------------------------------------

	* Collapse variables across schemes
	collapse (sum) water_gap (mean) share_plot_def, by(week)
	
	* Create graph
	twoway 	(bar share_plot_def week, bcolor(eltblue) ytitle("Share of plots")) ///
			(line water_gap week, lcolor(edkblue) lwidth(0.5) yaxis(2)), ///
			graphregion(color(white)) bgcolor(white) ///
			ytitle("Daily volume (mm/hectare)", axis(2)) ///
			legend(label(1 "Share of plots in deficit") label(2 "Total scheme daily" "water gap")) ///
			xlabel(27 "Jul 15" 54 "Jan 16" 80 "Jul 16" 106 "Jan 17") ///
			xtitle("") ///
			title(Pooled schemes) ///
			name(schemeAll)

* ------------------------------------------------------------------------------
* 						Combine and export graphs
* ------------------------------------------------------------------------------

	* Combine graphs
	gr 	combine schemeAll scheme10 scheme20 scheme30, ///
				cols(2) ycommon xcommon iscale(.4) ///
				graphregion(color(white))
	
	* Export graph
	gr export	"$out_plots\F3_Water_gap_distribution.png", width(5000) replace
	
	gr drop _all

	
********************************************************************************
*			PART 5: Relationship between requirements and availability
********************************************************************************	
	
	* Load data set
	use "$analysis_dt\furrow_week.dta", clear
	
	* Create water net of rain
	reg 	totwater rain
	predict yhat
	gen 	totwater_hat = totwater - yhat
	
	gen 	post_x_water_reqday = post * water_reqday
	estimates clear 
	
	* Treament effect															
	reg 	totwater water_reqday post post_x_water_reqday rain if water_reqday > 0
	
	* Save coefficients for graph
	local   beta_pre = round(_b[water_reqday],0.001)
	local 	beta_post = round(_b[water_reqday] + _b[post_x_water_reqday],0.001)
	
	* Save F-test P-values for graph
	test 	_b[water_reqday] = 1
	local 	f_pre = round(r(p),0.001)
	test 	_b[water_reqday] + _b[post_x_water_reqday] = 1
	local 	f_post = round(r(p),0.001)
	
	
	* Create graph
	twoway 	(lfitci totwater_hat water_reqday if post == 1 & water_reqday > 0, color("222 235 247") lwidth(.05)) ///
			(lfitci totwater_hat water_reqday if post == 0 & water_reqday > 0, color(gs15)) /// This the killer graph
			(lfit water_reqday water_reqday if post == 1 & water_reqday > 0, color(red) lwidth(.5) lpattern(dash)) ///
			(lfit totwater_hat water_reqday if post == 0 & water_reqday > 0, color(gs8) lwidth(.5)) /// This the killer graph
			(lfit totwater_hat water_reqday if post == 1 & water_reqday > 0, color(edkblue) lwidth(.5)), ///
			text(3 6.5 "Pre-feedback" "Regression coefficent: 0`beta_pre'" "P-value of coefficent = 1: 0`f_pre'" ///
				 15 5.5 "Post-feedback" "Regression coefficent: `beta_post'" "P-value of coefficent = 1: 0`f_post'", ///
				 orient(horizontal) size(vsmall) justification(center) fcolor(white) box margin(small)) ///
			xtitle("Water requirement (mm/day)") ///
			ytitle("Water availability, net of rain (mm/day)") ///
			legend(order (6 "Pre-feedback" 7 "Post-feedback" 3 "Pre-feedback 95%CI" 1 "Post-feedback 95%CI")) ///
			graphregion(color(white)) bgcolor(white)
			
	gr export	"$out_plots/corr_avail_req.png", width(5000) replace
	
	
	
********************************************************************************
*				PART 6: Share of plots with negative water gap by week
********************************************************************************		
	
	* Load data	
	use "$analysis_dt\plotweek_watergap.dta", clear
	
	* Set the first week in the data (which was in July 2015) to 1
	replace week = week - 27 														

	* Collapse per week
	collapse 	post water_gap areacult reqvolume totwater_volume ///
				rainwater_volume water_gap_neg, ///
				by(week tmt_hh)
				
	* Locals for graph
	local tmt_week 73
					
	* Plot
	twoway 		(bar rainwater_volume week, bcolor(gs13) yaxis(2) ytitle("Rainfall (mm/day)", axis(2))) ||  ///
				(line water_gap_neg week if tmt_hh == 1, lcolor(navy) yaxis(1) yscale(alt) yscale(alt axis(2))) || ///
				(line water_gap_neg week if tmt_hh == 0, lcolor(maroon) xline(73, lcolor(gs9) lpattern(dash)) yaxis(1)), ///
				xlabel(2 "Jul/15" 28 "Jan/16" 54 "Jul/16" 80 "Jan/17" 106 "Jul/17" 132 "Jan/18") ///
				ytitle("Proportion of plots with negative water gap ", axis(1)) ///
				xtitle("") ///
				legend(order(1 "Rainfall" 2 "Individual feedback" 3 "General feedback") cols(3) symxsize(3.5)) ///
				graphregion(color(white)) bgcolor(white)
	
	* Save 
	gr export	"$out_plots/Event study.png", width(5000) replace	
	

********************************************************************************
*					PART 7: Water availability and precipitation 
*							before information treatment
********************************************************************************

	* Load data
	use "$analysis_dt/water_plot_long.dta", clear	
	drop if post == 1															// only pre-treatment

	* Collapse by scheme and week
	collapse water rain, by(scheme_id week)

	twoway 	(bar rain week, xtitle() ytitle("Precipitation mm/day", axis(2))  ///
				yaxis(2) bcolor(bluishgray)) 	///
			(line water week if scheme_id == 10, lcolor(edkblue) lwidth(0.5) ytitle("Water availability mm/day")) ///
			(line water week if scheme_id == 20, lcolor(emidblue) lwidth(0.5))	///
			(line water week if scheme_id == 30, lcolor(ebblue) lwidth(0.5)), 	///
			legend(order(1 "Precipitation" 2 "Scheme 1" 3 "Scheme 2" 4 "Scheme 3")) ///
			xlabel(27 "Jul 15" 53 "Jan 16" 79 "Jul 16" 105 "Jan 17") ///
			graphregion(color(white)) bgcolor(white)

	gr export	"$out_plots/A4_Water_Precip_Trend.png", width(5000) replace
	

********************************************************************************
*							PART 9: Month of planting
********************************************************************************		
	
	use 	"$analysis_dt\hhwater_plotcropgs.dta", clear
	
	* Restrict sample
	* ---------------
	* limit to a full year in which all plots are likely to have completed their full cycle before the last survey pre-feedback in Nov 16.
	keep if mthplant >= 7 & mthplant <= 19
	
	* limit to counting all the crops that we have estimated planting date and the cycle was completed.
	* This drops any crops that might have been planted in Jul 15, but wouldn't have been harvested yet in november
	keep if mthharv != . & mthplant != .
	
	* Aggregate observations
	* ----------------------
	* Count number of observations by month
	collapse (count) crops_no = crop_id, by(mthplant)
	
	* Calculate share of crops planted in each month
	egen crops_total = sum(crops_no)	
	qui sum crops_total
	gen proportion = 100*(crops_no/crops_total)
	
	* Create and export graph
	* -----------------------	
	* Create graph
	twoway 	bar proportion mthplant, ///
			ylabel(0 "0" 5 "5" 10 "10" 15 "15") ///
			xlabel(7(1)19, valuelabel angle(45)) ///
			xtitle(" " "Month of planting") ///
			ytitle("% of crops planted and harvested" "between July 2015 and July 2016") ///
			barwidth(.9) ///
			graphregion(color(white)) bgcolor(white)
	
	* Save graph
	gr export "$out_plots/month_planting_1yr_perc.png", width(5000) replace
