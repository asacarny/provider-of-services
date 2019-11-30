* process provider of services file

set more off
capture log close
log using pos.log, replace
clear

* use POS data from these years
global STARTYEAR = 1993
global ENDYEAR = 2017

**** source of POS data ***

* the repository includes a script, download_source.sh, which you can
* use to pull the source data from the NBER website
* (if you are an NBER affiliate, the script can download it through rsync over
* ssh)

* however, if you don't want to use the script, the data files are available
* here:
* http://www.nber.org/data/provider-of-services.html
* they are the 'Stata' 'Other' files. For pre-2011 years, use the PROV link.

* each year's file assumed to have the following path:
* $POSBASE/pos`year'.dta
* edit the 'use ... using' statement below if your POS data follows a
* different directory structure

* base directory where POS data stored
global POSBASE = "source/"

* make the output folder if it doesn't exist
capture mkdir output

forvalues year = $STARTYEAR/$ENDYEAR {
	
	if (`year'<2011) {
		local category_provider "prov0075"
		local city "prov3225"
		local name "prov0475"
		local address "prov2720"
		local tel "prov1605"
		
		if (`year' == 1993) {
			local termcode = "prov2805"
			local termdate "prov2810"
		}
		else {
			local termcode = "prov4770"
			local termdate "prov4500"
		}
		
		local partdate "prov1565"

		local prev_pn "prov0300"
				
		local zip "prov2905"
		local urbancbsa ""
		local medaffil "prov0645"
		local resprog_ada "prov1805"
		local resprog_ama "prov1810"
		local resprog_aoa "prov1815"
		local resprog_oth "prov1820"
		local residents "prov1165"
		local pn "prov1680"
		local provider_subtype "prov0085"
		local typ_control "prov2885"
		local state "prov3230"
		local beds_tot "prov0740"
		local beds_cert "prov0755"
		

	}
	else {
		local category_provider "prvdr_ctgry_cd"
		local city "city_name"
		local name "fac_name"
		local address "st_adr"
		local tel "phne_num"
		
		local termcode "pgm_trmntn_cd"
		local termdate "trmntn_exprtn_dt"
		local partdate "orgnl_prtcptn_dt"
		
		* uses a different name but only in 2011!
		if (`year'==2011) {
			local prev_pn "cross_ref_provider_number"
		}
		else {
			local prev_pn "cross_rfrnc_prvdr_num"
		}

		local zip "zip_cd"
		local urbancbsa "cbsa_urbn_rrl_ind"
		local medaffil "mdcl_schl_afltn_cd"
		if (`year'<=2012) {
			local resprog_ada "rsdnt_pgm_ada_aprvd_sw"
			local resprog_ama "rsdnt_pgm_ama_aprvd_sw"
			local resprog_aoa "rsdnt_pgm_aoa_aprvd_sw"
			local resprog_oth "rsdnt_pgm_othr_aprvd_sw"
		}
		else {
			local resprog_ada "rsdnt_pgm_dntl_sw"
			local resprog_ama "rsdnt_pgm_alpthc_sw"
			local resprog_aoa "rsdnt_pgm_ostpthc_sw"
			local resprog_oth "rsdnt_pgm_othr_sw"
		}
		
		local residents "rsdnt_physn_cnt"
		local pn "prvdr_num"
		local provider_subtype "prvdr_ctgry_sbtyp_cd"
		local typ_control "gnrl_cntl_type_cd"
		local state "state_cd"
		local beds_tot "bed_cnt"
		local beds_cert "crtfd_bed_cnt"
		

	}

	use `category_provider' `city' `name' `address' `tel' ///
		`prev_pn' `termcode' `termdate' `partdate' `zip' `urbancbsa' `medaffil' ///
		`resprog_ada' `resprog_ama' `resprog_aoa' `resprog_oth' `residents' ///
		`pn' `provider_subtype' `typ_control' `state' `beds_tot' `beds_cert'  ///
		if `category_provider'=="01" ///
		using $POSBASE/pos`year'.dta
	gen year = `year'

	* already restricting to hospitals in 'use' statement
	* i.e. category_provider==01
	rename `category_provider' category_provider
	drop category_provider

	rename `city' city
	rename `name' name
	rename `address' address

	* sometimes tel is set to .
	rename `tel' tel
	replace tel = "" if tel=="."
	
	* zero pad the zip code
	rename `zip' zip
	tostring zip, replace format(%05.0f)
	assert length(zip)==5 if !missing(zip)

	if ("`urbancbsa'"!="") {
		rename `urbancbsa' urbancbsa
		replace urbancbsa = "1" if urbancbsa=="U"
		replace urbancbsa = "0" if urbancbsa=="R"
		destring urbancbsa, replace
	}
	else {
		gen byte urbancbsa = .
	}
	rename `termcode' termcode
	rename `termdate' termdate
	rename `partdate' partdate
	rename `prev_pn' prev_pn

	* fix date variables stored as strings
	
	* in 1993-1995, termdate and partdate are stored as YYMMDD not YYYYMMDD like later
	* years. change to YYYYMMDD
	* NOTE: doing this for any year <=1995, assuming that years before 1993 did this too
	if (`year'<=1995) {
		replace termdate = "19"+termdate if length(termdate)==6
		replace partdate = "19"+partdate if length(partdate)==6
	}
	
	* deal with termdate and partdate
	*
	* weirdly, in 2011 and 2011 alone, termdate and partdate as stored properly
	* as stata internal date format
	* otherwise they are stored as strings YYYYMMDD (pre 2011) or as longs in
	* the format YYYYMMDD (post 2011), both of which need to be converted to
	* stata internal date format
	if (`year'!=2011) {
		if (`year'>=2012) {
			tostring termdate partdate, replace
		}
		
		* fix the variables
		foreach var of varlist termdate partdate {
			gen `var'dt = mdy(real(substr(`var',5,2)),real(substr(`var',7,2)),real(substr(`var',1,4)))
			drop `var'
			rename `var'dt `var'
		}
	}
	
	format termdate %td
	format partdate %td
			
	rename `medaffil' medaffil
	rename `resprog_ada' resprog_ada
	rename `resprog_ama' resprog_ama
	rename `resprog_aoa' resprog_aoa
	rename `resprog_oth' resprog_oth
	rename `residents' residents
	rename `pn' pn
	rename `provider_subtype' provider_subtype
	rename `typ_control' typ_control
	rename `state' state
	rename `beds_tot' beds_tot
	rename `beds_cert' beds_cert

	destring zip medaffil, replace

	* prov1810 - AMA-approved resident program
	* prov1805 - ADA
	* prov1815 - AOA
	* prov1820 - other

	* resident programs variables are Y/N
	foreach var of varlist resprog_* {
		replace `var' = "0" if `var'=="N"
		replace `var' = "1" if `var'=="Y"
	}
	destring resprog_*, replace

	* TERMINATION CODE
	*     VALUES:   00                  ACTIVE
	*               01                  VOL-MERG,CLOSE
	*               02                  VOL-REIMBURSE
	*               03                  VOL-RISK INVOL
	*               04                  VOL-OTHER
	*               05                  INVOL-FAIL REQ
	*               06                  INVOL-AGREEMNT
	*               07                  OTH-STATUS CHG

	* LABELS CHANGED IN 2011
	*                  01=VOLUNTARY-MERGER, CLOSURE
	*                  02=VOLUNTARY-DISSATISFACTION WITH REIMBURSEMENT
	*                  03=VOLUNTARY-RISK OF INVOLUNTARY TERMINATION
	*                  04=VOLUNTARY-OTHER REASON FOR WITHDRAWAL
	*                  05=INVOLUNTARY-FAILURE TO MEET HEALTH/SAFETY REQ
	*                  06=INVOLUNTARY-FAILURE TO MEET AGREEMENT
	*                  07=OTHER-PROVIDER STATUS CHANGE

	label define termcode 0 "active" 1 "vol-merg,close" 2 "vol-reimburse" 3 "vol-risk invol" ///
		4 "vol-other" 5 "invol-fail req" 6 "invol-agreemnt" 7 "oth-status chg"
	destring termcode, replace
	label values termcode termcode
	gen active = termcode==0

	* prov0645 - med school affiliation
	*     VALUES:   1                   MAJOR
	*               2                   LIMITED
	*               3                   GRADUATE
	*               4                   NO AFFILIATION

	label define medaffil 1 "major" 2 "limited" 3 "graduate" 4 "no affiliation"
	label values medaffil medaffil


	* prov0655 - medicare vendor number

	* drop if pn==""
	* drop if length(pn) != 6

	* prov0085 - type of hospital
	* 01 short term
	* 11 cah
	*     VALUES:      01=SHORT TERM
	*                  02=LONG TERM
	*                  03=RELIGIOUS NONMEDICAL HEALTH CARE INSTITUTIONS
	*                  04=PSYCHIATRIC
	*                  05=REHABILITATION
	*                  06=CHILDRENS'
	*                  07=DISTINCT PART PSYCHIATRIC HOSPITAL
	*                  11=CRITICAL ACCESS HOSPITALS
	*                  20=TRANSPLANT HOSPITALS
	*                  22=MEDICAID ONLY NON-PSYCHIATRIC HOSPITAL
	*                  23=MEDICAID ONLY PSYCHIATRIC HOSPITAL
	destring provider_subtype, replace
	label define subtype 1 "short term" 2 "long term" 3 "religious nonmedical" ///
		4 "psych" 5 "rehab" 6 "childrens" 7 "distinct part psych" 11 "cah" ///
		20 "transplant" 22 "mcaid only non-psych" 23 "mcaid only psych"
	label values provider_subtype subtype
	gen shortterm = provider_subtype==1
	gen cah = provider_subtype==11

	* prov2885 - type of control
	* 01                  VOLUNTARY NON-PROFIT - CHURCH
	* 02                  VOLUNTARY NON-PROFIT - PRIVATE
	* 03                  VOLUNTARY NON-PROFIT - OTHER
	* 04                  PROPRIETARY
	* 05                  GOVERNMENT - FEDERAL
	* 06                  GOVERNMENT - STATE
	* 07                  GOVERNMENT - LOCAL
	* 08            	   GOV. - HOSP. DIST. OR AUTH.

	* new labels in 2011
	*   VALUES:      01=CHURCH
	*                  02=PRIVATE (NOT FOR PROFIT)
	*                  03=OTHER (SPECIFY)
	*                  04=PRIVATE (FOR PROFIT)
	*                  05=FEDERAL
	*                  06=STATE
	*                  07=LOCAL
	*                  08=HOSPITAL DISTRICT OR AUTHORITY
	*                  09=PHYSICIAN OWNERSHIP
	*                  10=TRIBAL


	destring typ_control, replace
	label define control 1 "non-profit church" 2 "non-profit private" 3 "non-profit other" ///
		4 "for-profit proprietary" 5 "government federal" 6 "government state" ///
		7 "government local" 8 "government hosp district/authority" 9 "for-profit phys owned" ///
		10 "government tribal"
	label values typ_control control

	gen nonprofit = typ_control>=1 & typ_control<=3
	gen forprofit = typ_control==4 | typ_control==9
	gen govt = (typ_control>=5 & typ_control <= 8) | typ_control==10

	* prov3230 - state abbreviation
	gen maryland = state=="MD"
	gen nonstate = state=="AS"|state=="CN"|state=="GU"|state=="MP"|state=="MX"|state=="PR"|state=="VI"

	compress
	save pos`year'.dta, replace
	clear
}

forvalues year = $STARTYEAR/$ENDYEAR {
	if (_N==0) {
		use pos`year'.dta
	}
	else {
		append using pos`year'.dta
	}
	
	rm pos`year'.dta
}


label variable pn "hospital medicare provider number"
label variable year "year of POS data"
label variable active "is hospital active"
label variable termcode "termination code"
label variable termdate "termination date"
label variable partdate "participation date"
label variable prev_pn "previous provider number"
label variable name "name of hospital"
label variable address "address"
label variable city "city"
label variable state "state"
label variable urbancbsa "urban CBSA (2011-)"
label variable zip "zip code"
label variable tel "telephone number"
label variable medaffil "affiliation with medical school"
label variable resprog_ada "ADA-approved resident program / dental residency (2013-)"
label variable resprog_ama "AMA-approved resident program / allopathic residency (2013-)"
label variable resprog_aoa "AOA-approved resident program / osteopathic residency (2013-)"
label variable resprog_oth "other resident program"
label variable residents "number of residents"
label variable shortterm "is hospital short term"
label variable cah "is hospital critical access (CAH)"
label variable provider_subtype "subtype of provider"
label variable typ_control "type of hospital control"
label variable nonprofit "is hospital non-profit"
label variable forprofit "is hospital for-profit"
label variable govt "is hospital government-run"
label variable maryland "is hospital located in maryland"
label variable nonstate "is hospital located in a US territory or Canada, not a state/DC"
label variable beds_tot "total hospital beds"
label variable beds_cert "certified hospital beds"

* some data checks
foreach var of varlist _all {
	gen byte MISS_`var' = missing(`var')
	mean MISS_`var', over(year)
	drop MISS_`var'
}

order ///
	pn year name address city state zip tel active termcode termdate partdate prev_pn ///
	medaffil resprog_* residents ///
	shortterm cah provider_subtype typ_control nonprofit forprofit govt ///
	maryland nonstate urbancbsa beds_tot beds_cert

compress
sort pn year

save output/pos.dta, replace
saveold output/pos.v11.dta, replace version(11)
export delimited output/pos.csv, replace

log close

quietly {
    log using output/pos_codebook.txt, text replace
    noisily describe, fullnames
    log close
}

log using pos.log, append

* file of the first time a record was seen for each pn
preserve
egen firstyear = min(year), by(pn)
keep if year==firstyear
drop year

label variable firstyear "year of POS data (and first year pn appeared in data)"

sort pn
save output/pos_firstyear.dta, replace
saveold output/pos_firstyear.v11.dta, replace version(11)
export delimited output/pos_firstyear.csv, replace

log close

quietly {
    log using output/pos_firstyear_codebook.txt, text replace
    noisily describe, fullnames
    log close
}

log using pos.log, append

restore


* file of the last time a record was seen for each pn
egen lastyear = max(year), by(pn)
keep if year==lastyear
drop year

label variable lastyear "year of POS data (and last year pn appeared in data)"

sort pn
save output/pos_lastyear.dta, replace
saveold output/pos_lastyear.v11.dta, replace version(11)
export delimited output/pos_lastyear.csv, replace

log close

quietly {
    log using output/pos_lastyear_codebook.txt, text replace
    noisily describe, fullnames
    log close
}

log using pos.log, append

log close
