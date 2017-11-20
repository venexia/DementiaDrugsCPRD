qui {

	* Load data

	use "$data/dem_master.dta", clear

	* Restrict data to patients with linked data for both the HES inpatient dataset and ONS death registry

	merge 1:1 patid using "$path/data/link/link_c_linkage_eligibility.dta", keepusing (hes_e death_e) keep(match)
	keep if hes_e==1 & death_e==1 
	local N = _N
	noi di "Total number of patients with linked data for both the HES inpatient dataset and ONS death registry: `N'"
	
	* Remove unnecessary variables from dataset

	keep diagnosis_dem $dem_cond_date hesip*_date death*_date

	* Generate binary variables for each of the date variables

	foreach x of varlist *_date {
		local y = subinstr("`x'","_date","",.)
		gen `y' = cond(missing(`x'),0,1)
		drop `x'
	}

	* Determine the patients diagnosis in each of the matched datasets

	foreach i in hesip death {

		egen `i'_ad = rowmax(`i'_adprob `i'_adposs)

		gen diagnosis_`i' = .
		replace diagnosis_`i' = 0 if `i'_vas==0 & `i'_ad==0 & `i'_oth==0
		replace diagnosis_`i' = 1 if `i'_adprob==1 & `i'_vas==0 & `i'_oth==0
		replace diagnosis_`i' = 2 if `i'_adposs==1 & `i'_adprob==0 & `i'_vas==0 & `i'_oth==0
		replace diagnosis_`i' = 3 if `i'_ad==0 & `i'_vas==1 & `i'_oth==0
		replace diagnosis_`i' = 3 if `i'_ad==0 & `i'_vas==0 & `i'_oth==1
		replace diagnosis_`i' = 3 if `i'_adprob==1 & (`i'_vas==1 | `i'_oth==1)
		replace diagnosis_`i' = 3 if `i'_adposs==1 & `i'_adprob==0 & (`i'_vas==1 | `i'_oth==1)
		replace diagnosis_`i' = 3 if `i'_ad==0 & `i'_vas==1 & `i'_oth==1
		replace diagnosis_`i' = 3 if `i'_vas==0 & `i'_ad==0 & `i'_oth==0 & `i'_ns==1
		
		#delimit ;
		label define diagnosis
		0 "No dementia"
		1 "Probable AD"
		2 "Possible AD"
		3 "Non-AD or mixed dementia"
		, replace;
		#delimit cr

		label values diagnosis_`i' diagnosis
	}

	
	* Calculate sensitivity and specificity of diagnoses

	foreach name in hesip_diag death_diag {
		matrix `name' = J(3,4,.)
		matrix colnames `name' = CPRD Linked Sensitvity Specificity //tp fn tn fp
		matrix rownames `name' = adprob adposs adnon
	}
	foreach source in hesip death {
		forval i=1/3 {
			count if diagnosis_dem==`i'
			local cprd = r(N)
			matrix `source'_diag[`i',1] = `cprd'
			count if diagnosis_`source'==`i'
			local link = r(N)
			matrix `source'_diag[`i',2] = `link'
			count if diagnosis_`source'==`i' & diagnosis_dem==`i'
			local tp = r(N)
			// matrix `source'_diag[`i',5] = `tp'
			count if diagnosis_`source'==`i' & diagnosis_dem!=`i'
			local fn = r(N)
			// matrix `source'_diag[`i',6] = `fn'
			local sens = 100*(`tp')/(`tp'+`fn')
			matrix `source'_diag[`i',3] = round(`sens',0.1)
			count if diagnosis_`source'!=`i' & diagnosis_dem!=`i'
			local tn = r(N)
			// matrix `source'_diag[`i',7] = `tn'
			count if diagnosis_`source'!=`i' & diagnosis_dem==`i'
			local fp = r(N)
			// matrix `source'_diag[`i',8] = `fp'
			local spec = 100*(`tn')/(`tn'+`fp')
			matrix `source'_diag[`i',4] = round(`spec',0.1)
		}
	}
	
	noi matrix list hesip_diag 
	noi matrix list death_diag

}
