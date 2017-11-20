* Define colour schemes

local brewer1 "94 60 153"
local brewer2 "178 171 210"
local brewer3 "253 184 99"

* Create temporary data folder for intermediate datasets

mkdir "$data/temp"

* Load data

use "$data/dem_master.dta", clear

* Generate variable indicating year of dementia diagnosis

gen dem_year = cond(diagnosis_dem>0,year(dem_cond_date),.)
save "$data/dembargraph.dta", replace
use "$data/dembargraph.dta", clear

* Remove patients without a dementia diagnosis

drop if missing(dem_year)

* Create dataset detailing the number of patients diagnosed each year

tab dem_year diagnosis_dem, matcell(dem) 
levelsof dem_year, local(row_levels)
mat rownames dem = `row_levels' // note: colnames refer to coding of diagnosis_dem
keep dem_year
rename dem_year year
duplicates drop
sort year
svmat dem
save "$data/temp/demyear.dta", replace

* Create dataset detailing the number of patients in the CPRD each year

use "$path/data/master.dta", clear
drop if region>10 // Restrict data to patients in English practices
keep patid data_start data_end lcd dem_cond_date diagnosis_dem // Remove unnecessary variables from dataset
keep if year(data_start)<2016 & year(lcd)==2016
forval i=1987/2015 {
	gen temp`i' = cond(data_start<mdy(1,1,`i') & data_end>mdy(12,31,`i'),1,0)
	egen cprd`i' = total(temp`i')
}
keep cprd*
duplicates drop
gen id = 1
reshape long cprd, i(id) j(year)
drop id
save "$data/temp/cprdyear.dta", replace

* Match the information about number of dementia diagnoses and number of patients in the CPRD to each year

use "$data/temp/cprdyear.dta", clear
merge 1:1 year using "$data/temp/demyear.dta"
drop _merge
foreach var of varlist _all {
 replace `var' = 0 if missing(`var')
}
save "$data/dembargraph.dta", replace

* Create variables for stacking bar graph that dementia diagnoses

use "$data/dembargraph.dta", clear
gen tot_1 = dem1
forval j = 2/3 {
	local i = `j'-1
	gen tot_`j' = tot_`i'+dem`j'
}
gen low = 0
gen lab = -100

* Create bar graph

#delimit ;
graph twoway
	(rbar tot_3 low year, color("`brewer3'") horizontal)
	(rbar tot_2 low year, color("`brewer2'") horizontal)
	(rbar tot_1 low year, color("`brewer1'") horizontal)
	(scatter year lab, mlabel(cprd) mcolor(none) mlabs(vsmall) mlabc(black) mlabp(9))
	,
	text(2019 -500 "Number of" "patients in" "the CPRD on" "January 1st", size(vsmall) j(right))
	xtitle("Number of patients diagnosed with dementia",size(vsmall)) 
	xlabel(0(500)4000,nogrid labsize(vsmall))
	xscale(range(-600 4000) titlegap(*10))
	ylabel(1987(1)2015, angle(horizontal) nogrid labsize(vsmall))
	ytitle("Year",size(vsmall)) 
	yscale(range(1987 2015) reverse titlegap(*10))
	legend(order(3 "Probable AD" 2 "Possible AD" 1 "Non-AD or mixed dementia") cols(3) size(vsmall) symx(3))
	scheme(s2mono);
# delimit cr
graph export "$output/DementiaDrugsCPRD_bargraph.tif", replace width(2250)

* Remove temporary data folder for intermediate datasets

!rmdir "$data/temp"  /s /q
