// Create empty regional matrix

local regions NorthEast NorthWest Yorkshire EastMidlands WestMidlands EastEngland SouthWest SouthCentral London SouthEastCoast	
local nations England NorthernIreland Scotland Wales
local columns study cprd

matrix R_pat = J(10,2,.)
matrix rownames R_pat = `regions'
matrix colnames R_pat = `columns'

matrix R_prac = J(10,2,.)
matrix rownames R_prac = `regions'
matrix colnames R_prac = `columns'

matrix N_pat = J(4,2,.)
matrix rownames N_pat = `nations'
matrix colnames N_pat = `columns'

matrix N_prac = J(4,2,.)
matrix rownames N_prac = `nations'
matrix colnames N_prac = `columns'

// Load data

use "$data/master.dta", clear
keep if diagnosis_dem>0

// Populate matrix with CPRD information

qui {

	forval i = 1/10 {
		count if region==`i'
		matrix R_pat[`i',2] = r(N)
		unique pracid if region==`i'
		matrix R_prac[`i',2] = r(sum)
	}
	
	count if region<11
	matrix N_pat[1,2] = r(N)
	unique pracid if region<11
	matrix N_prac[1,2] = r(sum)
	
	forval i = 2/4 {
		local j = `i'+9
		count if region==`j'
		matrix N_pat[`i',2] = r(N)
		unique pracid if region==`j'
		matrix N_prac[`i',2] = r(sum)
	}
	
}

// Restrict data to patients with dementia diagnosis and last collected data in 2016

keep if diagnosis_dem>0 & !missing(dem_cond_date) & dem_cond_date>=data_start & dem_cond_date<=data_end & dem_cond_date>=mdy(1,1,1987) & year(dem_cond_date)<2016 & year(lcd)==2016

// Populate matrix with study information

qui {	
	
	forval i = 1/10 {
		count if region==`i'
		matrix R_pat[`i',1] = r(N)
		unique pracid if region==`i'
		matrix R_prac[`i',1] = r(sum)

	}

	count if region<11
	matrix N_pat[1,1] = r(N)
	unique pracid if region<11
	matrix N_prac[1,1] = r(sum)
	
	forval i = 2/4 {
		local j = `i'+9
		count if region==`j'
		matrix N_pat[`i',1] = r(N)
		unique pracid if region==`j'
		matrix N_prac[`i',1] = r(sum)
	}
}

matrix list R_pat
matrix list R_prac
matrix list N_pat
matrix list N_prac
