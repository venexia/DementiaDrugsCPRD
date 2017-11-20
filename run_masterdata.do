* use raw patient data

use "$path/data/raw/patient_001.dta", clear

replace yob=yob+1800
		
gen pracid = mod(patid,1000)
merge m:1 pracid using "$path/data/raw/practice_001.dta"
drop _merge

keep patid pracid gender region yob frd crd uts tod lcd deathdate accept 

save "$data/master.dta", replace

* calculate data start and end dates

egen data_start = rowmax(crd uts)
egen data_end = rowmin(lcd tod deathdate)
format %td data_start data_end
save "$data/master.dta", replace
		
* merge all dementia codelists

local files : dir "$path/data/patlists" files "patlist_dem*.dta"

foreach file in `files' {
	local event =  substr(substr("`file'",1,length("`file'")-4),9,length("`file'")-8)
	use "$data/master.dta", clear
	merge 1:1 patid using "$path/data/patlists/`file'", keep(master match) keepusing(patid index_date)
	rename index_date `event'_date
	drop _merge
	save "$data/master.dta", replace
}

* merge linked data codelists

local files : dir "$path/data/link/patlists" files "*.dta"

foreach file in `files' {
	local event =  substr(substr("`file'",1,length("`file'")-4),9,length("`file'")-8)
	use "$data/master.dta", clear
	merge 1:1 patid using "$path/data/link/patlists/`file'", keep(master match) keepusing(patid index_date)
	rename index_date `event'_date
	drop _merge
	save "$data/master.dta", replace
}

* create master dementia event variables

egen dem_cond_date = rowmin($dem_cond_date $dem_treat_date)
egen dem_treat_date = rowmin($dem_treat_date)
egen dem_ad_date = rowmin(dem_adprob_date dem_adposs_date)

gen diagnosis_dem = .
replace diagnosis_dem = 0 if missing(dem_vas_date) & missing(dem_ad_date) & missing(dem_oth_date)
replace diagnosis_dem = 1 if !missing(dem_adprob_date) & missing(dem_vas_date) & missing(dem_oth_date)
replace diagnosis_dem = 2 if !missing(dem_adposs_date) & missing(dem_adprob_date) & missing(dem_vas_date) & missing(dem_oth_date)
replace diagnosis_dem = 3 if missing(dem_ad_date) & !missing(dem_vas_date) & missing(dem_oth_date)
replace diagnosis_dem = 3 if missing(dem_ad_date) & missing(dem_vas_date) & !missing(dem_oth_date)
replace diagnosis_dem = 3 if !missing(dem_adprob_date) & (!missing(dem_vas_date) | !missing(dem_oth_date))
replace diagnosis_dem = 3 if !missing(dem_adposs_date) & missing(dem_adprob_date) & (!missing(dem_vas_date) | !missing(dem_oth_date))
replace diagnosis_dem = 3 if missing(dem_ad_date) & !missing(dem_vas_date) & !missing(dem_oth_date)
replace diagnosis_dem = 3 if missing(dem_vas_date) & missing(dem_ad_date) & missing(dem_oth_date) & (!missing(dem_ns_date) | !missing(dem_treat_date))

#delimit ;
label define diagnosis
0 "No dementia"
1 "Probable AD"
2 "Possible AD"
3 "Non-AD or mixed dementia";
#delimit cr

label values diagnosis_dem diagnosis

gen treatment_dem = .
replace treatment_dem = 0 if missing(dem_don_date) & missing(dem_gal_date) & missing(dem_riv_date) & missing(dem_mem_date) 
replace treatment_dem = 1 if (!missing(dem_don_date) | !missing(dem_gal_date) | !missing(dem_riv_date)) & missing(dem_mem_date)
replace treatment_dem = 2 if missing(dem_don_date) & missing(dem_gal_date) & missing(dem_riv_date) & !missing(dem_mem_date)
replace treatment_dem = 3 if (!missing(dem_don_date) | !missing(dem_gal_date) | !missing(dem_riv_date)) & !missing(dem_mem_date)

#delimit ;
label define treatment
0 "None"
1 "AChE inhibitors only"
2 "Memantine only"
3 "Both";
#delimit cr

label values treatment_dem treatment

format %td *_date
save "$data/master.dta", replace

* Restrict data to patients in English practices

drop if region>10 

* Remove unnecessary variables from dataset

keep patid pracid region data_start data_end lcd dem_* diagnosis_dem $dem_cond_date hesip*_date death*_date

* Restrict data to patients with dementia diagnosis and last collected data in 2016

keep if diagnosis_dem>0 & !missing(dem_cond_date) & dem_cond_date>=data_start & dem_cond_date<=data_end & dem_cond_date>=mdy(1,1,1987) & year(dem_cond_date)<2016 & year(lcd)==2016

* Save dataset

save "$data/dem_master.dta", replace
