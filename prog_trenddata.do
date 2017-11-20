cap prog drop trenddata
prog def trenddata
args nname diagnosis treatment min_mo min_yr

	* Load data
	
	use "$data/dem_master.dta", clear
	
	* Restrict data to patients with the specified dementia diagnosis in the study period
	
	keep if `diagnosis' & data_end>=mdy(`min_mo',1,`min_yr')

	* Generate variables for the exposure and diagnosis dates
	
	egen expdate = rowmin(`treatment')
	replace expdate = cond(!missing(expdate) & expdate>=data_start & expdate<=data_end & expdate>=mdy(`min_mo',1,`min_yr') & year(expdate)<2016,expdate,.)
	gen diadate = dem_cond_date
	format %td expdate diadate
	keep patid diadate expdate data_start data_end diagnosis_dem
	
	* Generate a variable for each month from January 1987 to December 2015
	
	forval j = 1987/2015 {
		forval i = 1/12 {
			gen y`j'm`i' = 0
			replace y`j'm`i' = 1 if ym(year(diadate),month(diadate))<=ym(`j',`i')
			replace y`j'm`i' = 0 if ym(year(expdate),month(expdate))<ym(`j',`i')
			replace y`j'm`i' = 0 if ym(`j',`i')>=ym(year(data_end),month(data_end))
			replace y`j'm`i' = 0 if ym(`j',`i')<ym(year(data_start),month(data_start))
			replace y`j'm`i' = 0 if ym(`j',`i')==ym(year(data_start),month(data_start))
		}
	}
	local temp_yr = `min_yr'-1
	forval j = 1987/`temp_yr' {
		forval i = 1/12 {
			replace y`j'm`i' = .
		}
	}
	local temp_mo = `min_mo'-1
	forval i = 1/`temp_mo' {
		replace y`min_yr'm`i' = .
	}
	save "$data/`nname'_full.dta", replace 

	* Create an empty datset with an observation for each month from January 1987 to December 2015
	
	local obs = 12*(2016-1987)
	clear
	set obs `obs'
	
	* Generate month and year variables
	
	gen month = mod(_n,12)
	replace month = 12 if month==0
	egen year = seq(), from(1987) to(2015) block(12)
	gen date_ym = ym(year,month)
	
	* Generate empty variables for the number of diagnosed, exposed and their totals
	
	gen dia = .
	gen exp = .
	gen dia_total = .
	gen exp_total = .
	format %tm date_ym
	save "$data/`nname'.dta", replace

	* For each observation, i.e. for each month, extract the number of diagnosed and exposed
	
	forval j = 1(1)`obs' {
		use  "$data/`nname'.dta", clear
		local i = date_ym[`j']
		local y = year[`j']
		local m = month[`j']
		use  "$data/`nname'_full.dta", clear
		count if !missing(expdate)
		local exp_total = r(N)
		count if !missing(diadate)
		local dia_total = r(N)
		count if y`y'm`m'==1
		local dia = r(N)
		count if ym(year(exp),month(exp))==`i'
		local exp = r(N)
		use  "$data/`nname'.dta", clear
		replace dia = `dia' if date_ym==`i'
		replace exp = `exp' if date_ym==`i'
		replace dia_total = `dia_total' if date_ym==`i'
		replace exp_total = `exp_total' if date_ym==`i'		
		save "$data/`nname'.dta", replace
	}

	* Calculate the proportion of patients exposed and the standard error
	
	gen p_exp = exp/dia
	gen p_se = sqrt(p_exp*(1 - p_exp)/dia)
	gen date = year + ((month-1)/12)
	
	* Remove observations that refer to months prior to the study period
	
	drop if year<`min_yr'
	drop if year==`min_yr' & month<`min_mo'

	* Remove observations that do not have any exposed or diagnosed patients (necessary for JoinPoint Regression Analysis software)
	
	drop if dia==0 | exp==0
	
	* Save dataset and export to excel for use by JoinPoint Regression Analysis software

	save "$data/`nname'.dta", replace
	export excel p_exp p_se date using "$project/joinpoint/jp_`nname'_in.xlsx", firstrow(var) replace
	
end
