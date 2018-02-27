	
********************************************************************************
* Page 2:  Plot-level water use data was collected three times per day for XXX 
* consecutive weeks covering XXX plots in three irrigation schemes.
********************************************************************************

	use "$masterdata/master_plot.dta", clear
	drop if scheme_id == 20 & irrigation_type != 3 // 159 plots
	
	di $weekMax // 146 weekd

********************************************************************************
* Page 5: Specifically, the share of plots receiving sufficient water relative 
* to their crop requirements increased by 14.0 percentage points (from a 
* pre-information weekly average of XXX\% of plots)
********************************************************************************
	
	* % of household-round-plot-crop-gs obs in the pre period where water gap is negative:	
	use "$analysis_dt/plotweek_watergap.dta", clear
	tab water_gap_neg if post == 0 // 8640/11913 = .72525812
	tab water_gap_neg if post == 1 // 7708/9017 = .85482977
	
	
********************************************************************************
* Get list of households in the final sample
********************************************************************************
	
	* All households ever listed
	use "$masterdata/master_hh.dta", clear
	
	* Keep only households that are in the final sample: 
	preserve
		use 	"$analysis_dt\hhwater_plotcropgs.dta", clear
		drop if scheme_id == 20 & irrigation_type != 3
		keep hh_id 
		duplicates drop
		tempfile hh
		save `hh'
	restore
	
	merge 1:m hh_id using `hh', nogen keep(3) assert(1 3)

********************************************************************************
* Page 24: The initial pair-wise randomization was done after round 3 when XX
* households were assigned to the general feedback treatment and XX the
* individual feedback treatment. ... Across all rounds XX households were 
* assigned to general feedback and X to individual feedback
********************************************************************************

	tab tmt_hh	// 72 individual, 75 general across all rounds
	
	* Merge to original treatment assignment
	preserve
		merge 1:1 hh_id using "C:\Users\WB501238\Dropbox\WB\PROIRRI Survey\Measurement pilot\Data collections\Feedback tool materials\Tool1\feedback stats.dta", keep(3) // merge = 1: not present in that round, merge =2 : not in final sample
		tab tmt_hh	// 66 general treatment, 63 individual
	restore

********************************************************************************
* A total of XXX households were listed as part of the schemes
********************************************************************************
	
	count // 157

********************************************************************************
* of which: XXX were surveyed in at least one of the pre-feedback rounds (rounds 1-4)
********************************************************************************

	count if inlist(1,d_surveyed_fup1,d_surveyed_fup2,d_surveyed_fup3,d_surveyed_fup4) // 125

********************************************************************************
* and XXX responded to at least one of three post-feedback surveys (rounds 5-7).
********************************************************************************

	count if inlist(1,d_surveyed_fup5,d_surveyed_fup6,d_surveyed_fup7) // 129

********************************************************************************
* Finally, XX households responded to at least one pre-feedback and one 
********************************************************************************

	count if inlist(1,d_surveyed_fup1,d_surveyed_fup2,d_surveyed_fup3,d_surveyed_fup4) & inlist(1,d_surveyed_fup5,d_surveyed_fup6,d_surveyed_fup7) // 115
	
********************************************************************************
* Out of the XX and XX assigned to the general guidance and individual feedback, 
* respectively, XX and XX received at least one round of feedback.
********************************************************************************
	
	tab tmt_hh	// 72 individual, 75 general across all rounds
	tab tmt_hh if inlist(1,d_surveyed_fup4,d_surveyed_fup5,d_surveyed_fup6,d_surveyed_fup7) // 62 general, 66 individual
	
********************************************************************************
* X households that joined the schemes in round X did not receive any treatment. 
********************************************************************************
	
	count if tmt_hh == . & status != 3 // 8 hhs not randomized
	tab d_listed_fup1 if tmt_hh == . & status != 3
	tab d_listed_fup2 if tmt_hh == . & status != 3
	tab d_listed_fup3 if tmt_hh == . & status != 3
	tab d_listed_fup4 if tmt_hh == . & status != 3
	tab d_listed_fup5 if tmt_hh == . & status != 3	// Starting in FUP 5
	tab d_listed_fup6 if tmt_hh == . & status != 3
	tab d_listed_fup7 if tmt_hh == . & status != 3
	
********************************************************************************	
* Only XX\% of households assigned to individual feedback do not appear in any 
* post-feedback round, and only XX\% of households assigned to general feedback 
* do not appear in any post feedback round.  The p-value for the difference in
* these rates of attrition is .964.
********************************************************************************

	count if tmt_hh == 1 & inlist(1,d_surveyed_fup1,d_surveyed_fup2,d_surveyed_fup3,d_surveyed_fup4) 
	local total = r(N)
	count if tmt_hh == 1 & inlist(1,d_surveyed_fup1,d_surveyed_fup2,d_surveyed_fup3,d_surveyed_fup4) & inlist(1,d_surveyed_fup5,d_surveyed_fup6,d_surveyed_fup7)
	local post = r(N)
	di 1-(`post'/`total') // .06666667

	count if tmt_hh == 0 & inlist(1,d_surveyed_fup1,d_surveyed_fup2,d_surveyed_fup3,d_surveyed_fup4) 
	local total = r(N)
	count if tmt_hh == 0  & inlist(1,d_surveyed_fup1,d_surveyed_fup2,d_surveyed_fup3,d_surveyed_fup4)  & inlist(1,d_surveyed_fup5,d_surveyed_fup6,d_surveyed_fup7)
	local post = r(N)
	di 1-(`post'/`total') // .09230769
	
	gen attrition = inlist(1,d_surveyed_fup1,d_surveyed_fup2,d_surveyed_fup3,d_surveyed_fup4) & !inlist(1,d_surveyed_fup5,d_surveyed_fup6,d_surveyed_fup7)
	reg attrition tmt_hh 
	
/*     attrition |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
	-------------+----------------------------------------------------------------
		  tmt_hh |  -.0244444   .0417799    -0.59   0.559    -.1070207    .0581318
		   _cons |        .08   .0292398     2.74   0.007     .0222086    .1377914

	
* We further investigate selective attrition by testing whether the pre-feedback
* values of observables used to test balance in \ref{Tab:Balance_Table} can 
* predict attrition. We cannot reject that attrition is balanced on these 
* variables. A joint test of their significance has an F-stat of XX -> Attrition table do file
