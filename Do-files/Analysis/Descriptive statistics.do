/* *************************************************************************** *
*						Mozambique PRIORRI									   *												   
*																 			   *
*  PURPOSE:  			Generate descriptive statistics						   *		  
*  WRITEN BY:  			Luiza Andrade [lcardosodeandrad@worldbank.org]		   *
*  Last time modified:  Jan 2018											   *
*																			   *
********************************************************************************


	** OUTLINE:		TABLE 1 - Sample sizes by round
					TABLE 2 - Basic Descriptives of Sample Over Study Period
					TABLE 3 - Distribution of treatment and control assignment
				
	** REQUIRES:	$analysis\hhwater_plotcropgs.dta.dta
					$masterdata/master_hh.dta
					$masterdata/plot_tracker.dta
					$masterdata/master_plot.dta
	
	** CREATES:		$out_desc/T1_obs_per_round.tex
					$out_desc/T2_descriptives.tex
					$out_desc/T3_takeup.tex
				
	** NOTES:		
	
	

********************************************************************************
*						TABLE 1 - Sample sizes by round
*******************************************************************************/

* ------------------------------------------------------------------------------
* 						Household information
* ------------------------------------------------------------------------------

	* Load data
	use "$masterdata/master_hh.dta", clear
	
	merge 1:m hh_id using "$masterdata/plot_tracker.dta", keep(3)				// keeping only merged observations will drop households that only ever used non-sprinkler plots in Scheme 2 and
																				// plots with no household
	duplicates drop hh_id, force
	
	
	* Count number of households listed per round
	forvalues fup = 1/$fup_rounds {
		
			preserve
			
				use 	"$analysis_dt\hhwater_plotcropgs.dta", clear
				keep if round == `fup'
				
				duplicates drop hh_id, force										// Table is a household level
				keep hh_id
				
				tempfile hh
				save 	`hh'
				
			restore
			
		* In fup6, we listed owners and users of plots. In the other rounds,
		* we only listed users. To make numbers comparable, we'll use only
		* users in fup 6
		
		if `fup' != 6 {
		
			preserve
			
				merge 1:1 hh_id using `hh', nogen keep(3) assert(1 3)
				qui count if d_listed_fup`fup' == 1
				local  listed_fup`fup' = r(N)
				
				qui count if d_surveyed_fup`fup' == 1
				scalar survey_fup`fup' = round((r(N)/`listed_fup`fup'')*100,.1)
				scalar listed_fup`fup'	 = `listed_fup`fup''
				
			restore
			
		}
		else {
		
			preserve
			
				merge 1:1 hh_id using `hh', nogen keep(3) assert(1 3)
				qui count if d_user_fup`fup' == 1
				local  listed_fup`fup' = r(N)
				
				qui count if d_surveyed_fup`fup' == 1 & d_user_fup`fup' == 1
				scalar survey_fup`fup' = round((r(N)/`listed_fup`fup'')*100,.1)
				scalar listed_fup`fup'	 = `listed_fup`fup''
				
			restore
		}
	}

	
	
* ------------------------------------------------------------------------------
* 							Plot information
* ------------------------------------------------------------------------------

	* Load data
	use "$masterdata/plot_tracker.dta", clear									// Get complete list of plots and households
	drop if hh_id == .															// Drop plots that were never assigned to a household
	
	* Count number of plots listed per round
	forvalues fup = 1/$fup_rounds {
		unique plot_id if round == `fup'
		scalar  plots_fup`fup' = r(unique)
	}
	
	* Calculate share of plots used per round
	collapse (count) plot_id, by(hh_id round)
	forvalues fup = 1/$fup_rounds {
		sum plot_id if round == `fup'
		scalar  share_fup`fup' = round(r(mean),.01)
	}

* ------------------------------------------------------------------------------
* 							Write tex file
* ------------------------------------------------------------------------------

	capture file close descTable
	file open 	descTable using "$out_desc/T1_obs_per_round.tex", write replace
	file write 	descTable ///
		"\begin{tabular}{lccccccc}" _n ///
		"\hline\hline     \\[-1.8ex]" _n ///
		"                                             & \multicolumn{7}{c}{Round}        \\"  _n ///
		"\cline{2-8} \\[-1.8ex]"   _n /// 
		"                                             & 1    & 2    & 3    & 4    & 5   & 6 & 7 \\"  _n ///
		"\hline \\[-1.8ex]"   _n ///
		"Number of listed households                  & " %8.0gc (listed_fup1) "  & " %8.0gc (listed_fup2) "  & " %8.0gc (listed_fup3) "  & " %8.0gc (listed_fup4) "  & " %8.0gc (listed_fup5) "  & " %8.0gc (listed_fup6) " & " %8.0gc (listed_fup7) " \\" _n ///
		"Number of listed plots                       & " %8.0gc (plots_fup1)  "  & " %8.0gc (plots_fup2)  "  & " %8.0gc (plots_fup3)  "  & " %8.0gc (plots_fup4)  "  & " %8.0gc (plots_fup5)  "  & " %8.0gc (plots_fup6)  " & " %8.0gc (plots_fup7)  "\\"  _n ///
		"Average number of plots farmed per household & " %8.3gc (share_fup1)  "  & " %8.3gc (share_fup2)  "  & " %8.3gc (share_fup3)  "  & " %8.3gc (share_fup4)  "  & " %8.3gc (share_fup5)  "  & " %8.3gc (share_fup6)  " & " %8.3gc (share_fup7)  " \\" _n ///
		"Share of listed households surveyed          & " %8.0gc (survey_fup1) "\% & " %8.0gc (survey_fup2) "\% & " %8.0gc (survey_fup3) "\% & " %8.0gc (survey_fup4) "\% & " %8.0gc (survey_fup5) "\% & " %8.0gc (survey_fup6) "\% & " %8.0gc (survey_fup7) "\%  \\" _n ///
		"\hline\hline     \\[-1.8ex]" _n ///
		"\multicolumn{8}{p{1.1\textwidth}}{\footnotesize Notes: Two of the three schemes were included in round one, with the third added for round 2, causing the substantial increase in households and plots from round 1 to 2. During each round, households that weren't surveyed in any previous round are also asked about missed rounds retroactively, so reponse rates are expected to be higher for earlier rounds, as there were multiple occasions for households to be asked about their respective periods.} " _n ///
		"\end{tabular}"
	file close 	descTable
	
	
********************************************************************************
*			TABLE 2 - Basic Descriptives of Sample Over Study Period
********************************************************************************

* ------------------------------------------------------------------------------
* 							Calculate indicators
* ------------------------------------------------------------------------------

	* Load data
	use 	"$analysis_dt\hhwater_plotcropgs.dta", clear
	keep if round <= 3															// Round 2 is when the randomization was done

	* Get number of householdos listed and surveyed and number of plots per household
	preserve
	
		duplicates 	drop hh_id round, force
		collapse	(mean) d_surveyed_hh plots_count, by(scheme_id)
		replace 	d_surveyed_hh = d_surveyed_hh*100
		tempfile	hh
		save		`hh'		
	restore
	
	preserve
		duplicates 	drop hh_id, force
		collapse	(count) hh_id, by(scheme_id)
		merge 1:1 scheme_id using `hh', nogen		
		tempfile	hh
		save		`hh'		
	restore

	* Get number of plots listed
	preserve 

		duplicates 	drop plot_id, force
		collapse 	(count) plot_id, by(scheme_id)
			
		merge 1:1 scheme_id using `hh', nogen
		order scheme_id hh_id plot_id plots_count d_surveyed_hh
		save  `hh', replace			
		
	restore
	
	* Get average area per household
	preserve
	
		duplicates 	drop hh_id plot_id round, force
		
		collapse 	(sum) plotsize, 	by (hh_id scheme_id)
		collapse	(mean) plotarea = plotsize, 	by(scheme_id)
		
		tempfile	landholding
		save		`landholding'
		
	restore
	
	* Average plot size
	preserve
	
		duplicates 	drop plot_id round, force
		
		collapse	(mean) plotsize, 	by(scheme_id)
		
		tempfile	plotsize
		save		`plotsize'
	
		
	restore
	
	* Share of cultivated plots
	preserve
	
		collapse 	(max) d_plant, 		by (plot_id round scheme_id)
		collapse	(mean) d_plant, 	by(scheme_id)
		
		replace		d_plant = d_plant * 100
		
		tempfile	plant
		save		`plant'
	
		
	restore
	
	* Number of farmers cultivating each crop 
	preserve
	
		keep 		if inlist(crop_id, 8, 41, 39, 35, 18)
		duplicates 	drop hh_id crop_id, force
		
		collapse 	(count) hh_id, 	by (crop_id scheme_id)
		reshape		wide hh_id, 	i(scheme_id) j(crop_id)
		
		tempfile	hh_crop
		save		`hh_crop'
	
		
	restore
	
	
	* Average share of plot area dedicated to most common crops in baseline
	preserve
		gen			share = (areacult/plotsize)*100
		
		collapse 	(mean) share, 	by(plot_id crop_id hh_id scheme_id)
		collapse 	(mean) share, 	by(crop_id scheme_id)
		
		keep 		if inlist(crop_id, 8, 41, 39, 35, 18)
		
		reshape		wide share, 	i(scheme_id) j(crop_id)
		collapse	(mean) share*, 	by(scheme_id)
		
		tempfile 	share
		save		`share'
	restore
	
	* Merge everything
	use `hh', clear
	merge 1:1 scheme_id using `landholding', nogen
	merge 1:1 scheme_id using `plotsize', nogen
	merge 1:1 scheme_id using `plant', nogen
	merge 1:1 scheme_id using `hh_crop', nogen	
	merge 1:1 scheme_id using `share', nogen
	
* ------------------------------------------------------------------------------
* 					Adjust format before exporting
* ------------------------------------------------------------------------------
	
	* Change format of percentages
	foreach crop in 8 18 35 39 41 {
		replace hh_id`crop' =  (hh_id`crop'/hh_id)*100
	}
		
	* Make variables strings, so they're easier do adjust
	foreach varAux of varlist d_surveyed_hh d_plant share* hh_id8-hh_id41 {
		tostring `varAux', replace format(%9.1f) force
	}
	foreach varAux of varlist plots_count plotarea plotsize {
		tostring `varAux', replace format(%9.3f) force
	}
	foreach varAux of varlist d_* {
		tostring `varAux', replace force
	}
	
	foreach varAux of varlist _all {
		tostring `varAux', replace force
	}
	
	* Add leading zeroes and missing values
	foreach varAux of varlist _all {
		replace `varAux' = "-" 				if `varAux' == "." 
		replace `varAux' = "0" + `varAux' 	if substr(`varAux',1,1) == "." 
	}
	
	* Adjust number of decimals for percentages
	foreach varAux of varlist d_surveyed_hh d_plant share* hh_id8-hh_id41 {
		replace `varAux' = `varAux' + "\%" if `varAux' != "-"
	}
	
	
	* Add variables labels
	set obs `=_N+1'
	
	replace d_plant 		= "Share of cultivated plots" 					 in 4
	replace d_surveyed_hh	= "Share of listed households surveyed" 		 in 4
	replace plots_count 	= "Average number of plots farmed per household" in 4
	replace hh_id 			= "Number of listed households" 				 in 4
	replace plot_id 		= "Number of listed plots" 						 in 4
	replace plotarea		= "Average household landholding (ha)"			 in 4
	replace plotsize		= "Average plot size (ha) "						 in 4
	
	foreach varAux in share hh_id {
		replace `varAux'8 	= "Baby corn" 									 in 4
		replace `varAux'18 	= "Collard greens" 								 in 4
		replace `varAux'35 	= "Maize" 										 in 4
		replace `varAux'39 	= "Piri-Piri" 									 in 4
		replace `varAux'41 	= "Cabbage" 									 in 4
	}
	
	* Add scheme names
	replace scheme_id = "Scheme 1" 	if scheme_id == "10" 
	replace scheme_id = "Scheme 2" 	if scheme_id == "20" 
	replace scheme_id = "Scheme 3" 	if scheme_id == "30" 
	
	
	* Transpose
	sxpose, clear
	
	* Add section headers	(5 new lines)
	set obs  `=_N + 5'
	gen sort = 	_n
	 
	replace _var4 = "\\ \multicolumn{4}{c}{\textit{Sample sizes in baseline}} \\ \\" in 19
	replace _var4 = "\\ \multicolumn{4}{c}{\textit{General scheme characteristics in baseline}} \\ \\" in 20
	replace _var4 = "\\ \multicolumn{4}{c}{\textit{Share of households that planted common crops in baseline}} \\ \\" in 22
	replace _var4 = "\\ \multicolumn{4}{c}{\textit{Average share of plot area dedicated to most common crops in baseline}} \\ \\" in 23
	
	* Add irrigation type
	replace _var4 = "Irrigation type" 	in 21
	replace _var1 = "Canal" 			in 21
	replace _var2 = "Sprinkler" 		in 21
	replace _var3 = "Canal"				in 21
	
	* Put section headers on top of their respective sections
	replace sort = 5.6 in 21
	replace sort = 8.5 in 22
	replace sort = 5.5 in 20
	replace sort = 1.5 in 19
	replace sort = 13.5 in 23
	
	* Order variables and observations
	order 	_var4
	sort 	sort
	drop 	sort
	 
* ------------------------------------------------------------------------------
* 								Export table
* ------------------------------------------------------------------------------

	* Make variables' names compatible with data out
	rename _var4 v1
	rename _var1 v2
	rename _var2 v3
	rename _var3 v4
	 
	dataout, save("$out_desc/delete_me1") tex mid(1) nohead replace
	 
	* Remove document class line
	filefilter 	"$out_desc/delete_me1.tex" "$out_desc/delete_me2.tex", 	///		
				from("\BSdocumentclass[]{article}") ///
				to("") replace
	sleep $sleep
				
	* Remove set length line
	filefilter 	"$out_desc/delete_me2.tex" "$out_desc/delete_me1.tex", 	///		
				from("\BSsetlength{\BSpdfpagewidth}{8.5in} \BSsetlength{\BSpdfpageheight}{11in}") ///
				to("") replace
	sleep $sleep
	
	* Remove begin document line
	filefilter 	"$out_desc/delete_me1.tex" "$out_desc/delete_me2.tex", 	///		
				from("\BSbegin{document}") ///
				to("") replace
	sleep $sleep
				
	* Remove end document line
	filefilter 	"$out_desc/delete_me2.tex" "$out_desc/delete_me1.tex", 	///		
				from("\BSend{document}") ///
				to("") replace
	sleep $sleep
				
	* Remove extra spacing
	filefilter 	"$out_desc/delete_me1.tex" "$out_desc/delete_me2.tex", 	///		
				from("&  &  &  \BS\BS") ///
				to("") replace
	sleep $sleep
				
	* Make header line double
	filefilter 	"$out_desc/delete_me2.tex" "$out_desc/delete_me1.tex", 	///		
				from("\BSbegin{tabular}{lccc} \BShline") ///
				to("\BSbegin{tabular}{lccc} \BShline\BShline     \BS\BS[-1.8ex] ") replace
	sleep $sleep
				
	filefilter 	"$out_desc/delete_me1.tex" "$out_desc/delete_me2.tex", 	///		
				from("\BSend{tabular}") ///
				to("\BShline \BS\BS[-1.8ex] \BSmulticolumn{4}{@{}p{.9\BStextwidth}} {\BStextit{Notes}: Data refers to rounds 1-3 (rounds pre-feedback experiment). The number of listed households and plots indicates the total number of unique observations in those rounds. All other variables are averaged across the 3 rounds.} \BSend{tabular}") replace
	sleep $sleep
				
	* Make footer line double and add note
	filefilter 	"$out_desc/delete_me2.tex" "$out_desc/T2_descriptives.tex", 	///		
				from("24.1\BS% \BS\BS \BShline") ///
				to("24.1\BS% \BS\BS \BShline\BShline") replace
				
	* Delete delete mes		
	erase "$out_desc/delete_me1.tex"
	erase "$out_desc/delete_me2.tex"
	

********************************************************************************
*			TABLE 3 - Distribution of treatment and control assignment
********************************************************************************

* ------------------------------------------------------------------------------
* 								Load data
* ------------------------------------------------------------------------------

	use "$masterdata/master_hh.dta", clear
	
* ------------------------------------------------------------------------------
* 								Calculate numbers
* ------------------------------------------------------------------------------
	
	forvalues round = 4/$fup_rounds {											// Only for rounds when treatment was delivered
		forvalues tmtStatus = 0/1 {
			
			* Count number of households assigned to treatment
			count if tmt_hh == `tmtStatus' & d_listed_fup`round' == 1
			local listed = r(N)
			
			* Count number of household that actually received treatment
			count if tmt_hh == `tmtStatus' & d_listed_fup`round' == 1 & d_surveyed_fup`round' == 1
			local surveyed = r(N)
			
			* Calculate percentages
			scalar rate_fup`round'_g`tmtStatus' 	= (`surveyed'/`listed')*100
			scalar listed_fup`round'_g`tmtStatus' 	= `listed'
			scalar surveyed_fup`round'_g`tmtStatus' = `surveyed'
		}
	}
	
* ------------------------------------------------------------------------------
* 								Export table
* ------------------------------------------------------------------------------

	capture file close takeupTable
	file open 	takeupTable using "$out_desc/T3_takeup.tex", write replace
	file write 	takeupTable ///
		"\begin{tabular}{lcccccc}" 																																															  _n ///
		"\hline\hline     \\[-1.8ex]" 																																														  _n ///
		"& \multicolumn{2}{c}{Assignment} & \multicolumn{2}{c}{Survey response} & \multicolumn{2}{c}{Rate}       \\" 																										  _n ///
		"\cline{2-7} \\[-1.8ex]" 																																															  _n /// 
		"& \shortstack{Individual\\feedback}    & \shortstack{General\\feedback}    & \shortstack{Individual\\feedback}    & \shortstack{General\\feedback}   & \shortstack{Individual\\feedback}    & \shortstack{General\\feedback} \\" 																																  _n ///
		"\hline \\[-1.8ex]" 																																																  _n ///
		"First feedback round   & " %8.0gc (listed_fup4_g1) " & " %8.0gc (listed_fup4_g0) " & " %8.0gc (surveyed_fup4_g1) " & " %8.0gc (surveyed_fup4_g0) " & " %8.1f (rate_fup4_g1) "\% & " %8.1f (rate_fup4_g0) "\%  \\" _n ///
		"Second feedback round  & " %8.0gc (listed_fup5_g1) " & " %8.0gc (listed_fup5_g0) " & " %8.0gc (surveyed_fup5_g1) " & " %8.0gc (surveyed_fup5_g0) " & " %8.1f (rate_fup5_g1) "\% & " %8.1f (rate_fup5_g0) "\%  \\" _n ///
		"Third feedback round	 & " %8.0gc (listed_fup6_g1) " & " %8.0gc (listed_fup6_g0) " & " %8.0gc (surveyed_fup6_g1) " & " %8.0gc (surveyed_fup6_g0) " & " %8.1f (rate_fup6_g1) "\% & " %8.1f (rate_fup6_g0) "\%  \\" _n ///
		"Forth feedback round	 & " %8.0gc (listed_fup7_g1) " & " %8.0gc (listed_fup7_g0) " & " %8.0gc (surveyed_fup7_g1) " & " %8.0gc (surveyed_fup7_g0) " & " %8.1f (rate_fup7_g1) "\% & " %8.1f (rate_fup7_g0) "\%  \\" _n ///
		"\hline\hline" 																																																	  	  _n ///
		"\end{tabular}"
	file close 	takeupTable
