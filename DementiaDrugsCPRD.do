* Setup:

global path "E:/Dementia_CPRD_v2"
global project "$path/projects/DementiaDrugsCPRD_v2"
global dofiles "$project/dofiles"
global output "$project/output"
global data "$project/data"
cd $project
run "$path/dofiles/codedict.do"

* Create project specific dataset:

run "$dofiles/run_masterdata.do"

* Generate bar graph illustrating the number of patients diagnosed with dementia, by diagnosis type:

run "$dofiles/run_dembargraph.do"

* Create datasets necessary for trend analysis figures:

run "$dofiles/prog_trenddata.do"
local c = 0
foreach x in "diagnosis_dem==1" "(diagnosis_dem==1 | diagnosis_dem==2)" "diagnosis_dem>0" {
	qui {
		local c = `c'+1
		trenddata "AChE`c'" "`x'" "dem_gal_date dem_don_date dem_riv_date" 6 1997
		trenddata "mem`c'" "`x'" "dem_mem_date" 1 2003
	}
}

* Run joinpoint analysis using Joinpoint Regression Program (version 4.3.1.0; National Cancer Institute, USA)

* Generate trend analysis figures:

run "$dofiles/prog_trendgraphs.do"
local c = 0
foreach y in "probable AD" "any AD" "any dementia" {
	qui {
		local c = `c'+1
		trendgraphs "AChE`c'" "2012.000" "June 1997"
		trendgraphs "mem`c'" "2014.250" "January 2003"
	}
}

* Create output for the sensitivity analysis that investigates restricting to English practices:

do "$dofiles/run_sa_england.do"

* Create output for the sensitivity analysis that investigates sensitvity and specificity of dignoses:

do "$dofiles/run_sa_specificity.do"
