* Import data

import delimited "$data/googlenews_ad.csv", clear

* Sort dates

gen year = substr(time,1,4)
gen month = substr(time,6,2)
destring year month, replace
gen date = year + ((month-1)/12)
keep date interest
expand 2 in 49
gen generic = cond(_n < 50,0,1)
sort date generic

* Define colour schemes

local brewer1 "94 60 153"
local brewer2 "178 171 210"
local brewer3 "253 184 99"
local brewer4 "230 97 1"

* Create graph

local generic = "2012.000"

#delimit ;
twoway
(scatter interest date if generic==0, mcolor(gs6) msymbol(o) msize(small))
(scatter interest date if generic==1, mcolor("`brewer4'") msymbol(o) msize(small))
(scatter interest date if generic>1, mcolor(white) msymbol(o) msize(small)) // add space to legend for consistency with other graphs
,
name("`nname'", replace)
legend(order(1 "Monthly interest prior to patent expiry" 2 "Monthly interest post patent expiry" 3 "") size(vsmall) cols(1) pos(7) symxsize(2))
text(-19 2005
	"Study period: January 2008 - December 2015"
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
ytitle("Interest (Percentage of peak interest)",size(vsmall))
ylabel(0(5)100,angle(horizontal) nogrid labsize(vsmall) format(%2.0f)) 
yscale(titlegap(*8))
xline(2006.917)
text(100 2006.917 "A", size(vsmall) box bc(white))
xline(2007.667)
text(100 2007.667 "B", size(vsmall) box bc(white))
xline(2009.083)
text(100 2009.083 "C", size(vsmall) box bc(white))
xline(2011.167)
text(100 2011.167 "D", size(vsmall) box bc(white))
xline(2012.333)
text(100 2012.333 "E", size(vsmall) box bc(white))
xline(2015.083)
text(100 2015.083 "F", size(vsmall) box bc(white))
scheme(s2mono);
#delimit cr
graph export "$output/news.tif", replace width(2250)
