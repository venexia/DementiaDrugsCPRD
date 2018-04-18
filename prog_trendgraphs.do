cap prog drop trendgraphs
prog def trendgraphs
args nname generic first
	
	* Define colour schemes
	
	local brewer1 "94 60 153"
	local brewer2 "178 171 210"
	local brewer3 "253 184 99"
	local brewer4 "230 97 1"
	
	* Create locals for the number diagnosed and the number exposed
	
	use  "$data/`nname'.dta", clear
	local dia_total = dia_total[_N]
	local exp_total = exp_total[_N]
	
	* Import data concerning the model estimates from Joinpoint Regression Program (version 4.3.1.0; National Cancer Institute, USA)

	import excel "$project/joinpoint/jp_`nname'_out.xlsx", clear first sheet("Model Estimates")
	keep SlopeEstimate SlopeStdError Joinpoint Joinpoint95LCL Joinpoint95UCL

	* Determine the number of join points
	
	local N = _N	
	
	* Seperate date data into month and year to match existing data

	foreach item in Joinpoint Joinpoint95LCL Joinpoint95UCL {
		replace `item'= "" if `item'=="NA"
		destring(`item'), replace
		gen `item'_year = floor(`item')
		gen `item'_month = round(12*mod(`item',1))+1
		drop `item'
		gen `item' = ym(`item'_year,`item'_month)
		format `item' %tmMon_CCYY
		if "`item'"!="Joinpoint" {
			drop `item'_month `item'_year 
		}
	}
	
	* Create locals for the model estimate information
	
	forval i = 2/`N' {
		local j = `i'-1
		local jp_est_`j' = Joinpoint[`i']
		local jp_est_`j' : di %tmMon_CCYY `jp_est_`j''
		local jp_line_`j' = Joinpoint_year[`i'] + ((Joinpoint_month[`i']-1)/12)
		local jp_lcl_`j' = Joinpoint95LCL[`i']
		local jp_lcl_`j' : di %tmMon_CCYY `jp_lcl_`j''
		local jp_ucl_`j' = Joinpoint95UCL[`i']
		local jp_ucl_`j' : di %tmMon_CCYY `jp_ucl_`j''
		local jp_cap_`j' = "`jp_est_`j'' (95% CI: `jp_lcl_`j'' to `jp_ucl_`j'')"
	}

	* Create locals for the MPC information
	
	import excel "$project/joinpoint/jp_`nname'_out.xlsx", clear first sheet("APCs")
	local start = SegmentStart[1]
	local start : di %tmMonth_CCYY `start'
	keep APC APC95LCL APC95UCL
	forval i = 1/`N' {
		local MPC_est_`i' = APC[`i']
		local MPC_est_`i' : di %03.1f `MPC_est_`i''
		local MPC_lcl_`i' = APC95LCL[`i']
		if "`MPC_lcl_`i''" != "NA" {
			local MPC_lcl_`i' : di %03.1f `MPC_lcl_`i''
		}
		local MPC_ucl_`i' = APC95UCL[`i']
		if "`MPC_ucl_`i''" != "NA" {
			local MPC_ucl_`i' : di %03.1f `MPC_ucl_`i''
		}
		local MPC_CI_`i' = "`MPC_lcl_`i'' to `MPC_ucl_`i''"
		if "`MPC_lcl_`i''"=="NA" & "`MPC_ucl_`i''"=="NA" {
			local MPC_CI_`i' = "unknown"
		}
		local MPC_cap_`i' = "`MPC_est_`i'' (95% CI: `MPC_CI_`i'')"
	}
	
	* Create locals for the AMPC information
	
	import excel "$project/joinpoint/jp_`nname'_out.xlsx", clear first sheet("AAPCs")
	local AMPC_est = AAPC[1]
	local AMPC_est : di %03.1f `AMPC_est'
	local AMPC_low = AAPCCILow[1]
	local AMPC_low : di %03.1f `AMPC_low'
	local AMPC_high = AAPCCIHigh[1]
	local AMPC_high : di %03.1f `AMPC_high'
	
	* Create graph
	
	local AMPC_CI = "`AMPC_low' to `AMPC_high'"
	if "`AMPC_low'"=="NA" & "`AMPC_high'"=="NA" {
		local AMPC_CI = "unknown"
	}
	
	
	import excel "$project/joinpoint/jp_`nname'_out.xlsx", clear first sheet("Data")
	#delimit ;
	twoway
	(scatter p_exp date if date<`generic', mcolor(gs6) msymbol(o) msize(small))
	(scatter p_exp date if date>=`generic', mcolor("`brewer4'") msymbol(o) msize(small))
	(line Model date, lpattern(solid) lwidth(thin) lcolor(black))
	,
	name("`nname'", replace)
	legend(order(1 "Monthly proportion prior to patent expiry" 2 "Monthly proportion post patent expiry" 3 "JoinPoint model") size(vsmall) cols(1) pos(7) symxsize(2))
	text(-0.01 2005
		"Study period: `first' - December 2015"
		"Total eligible: `dia_total'; Total treated: `exp_total'"
		"(A) November 2006: NICE recommend restricting drug access" 
		"(B) February 2007: QOF revised to include dementia" 
		"(C) February 2009: First National Dementia Strategy launched"
		"(D) March 2011: NICE remove recommendation restricting drug access"
		"(E) May 2012: Prime Minister’s Dementia Challenge launched"
		"(F) February 2015: Prime Minister’s Dementia Challenge 2020 launched"
		, size(vsmall) just(left) place(se))
	xtitle("Time",size(vsmall))
	xlabel(1997(2)2015, angle(horizontal) labsize(vsmall)) 
	xscale(titlegap(*8))
	ytitle("Proportion of patients receiving a first prescription",size(vsmall))
	ylabel(0(0.01)0.05,angle(horizontal) nogrid labsize(vsmall) format(%4.2f)) 
	yscale(titlegap(*8))
	text(0.05 1997 "Joinpoints:" "`jp_cap_1'" "`jp_cap_2'" "`jp_cap_3'", size(vsmall) just(left) place(se))
	text(0.04 1997 "MPCs for each segment:" "`MPC_cap_1'" "`MPC_cap_2'" "`MPC_cap_3'", size(vsmall) just(left) place(se))
	text(0.03 1997 "AMPC for study period:" "`AMPC_est' (95% CI: `AMPC_CI')", size(vsmall) just(left) place(se))
	xline(2006.917)
	text(0.05 2006.917 "A", size(vsmall) box bc(white))
	xline(2007.667)
	text(0.05 2007.667 "B", size(vsmall) box bc(white))
	xline(2009.083)
	text(0.05 2009.083 "C", size(vsmall) box bc(white))
	xline(2011.167)
	text(0.05 2011.167 "D", size(vsmall) box bc(white))
	xline(2012.333)
	text(0.05 2012.333 "E", size(vsmall) box bc(white))
	xline(2015.083)
	text(0.05 2015.083 "F", size(vsmall) box bc(white))
	scheme(s2mono);
	#delimit cr
	graph export "$output/`nname'.tif", replace width(2250)

end

