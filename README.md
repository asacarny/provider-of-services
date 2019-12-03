# CMS Provider of Services Hospital Data 1993-2017

In this repository you'll find code to process the CMS Provider of Services hospital data. This data provides a host of basic information about hospitals like location, size, teaching status, and type of control (e.g. non-profit, for-profit, government). All hospitals from 1993-2017 are included. For more information, see this page at NBER:

https://www.nber.org/data/provider-of-services.html

The code produces three datasets. The main dataset, `pos.dta`, has a record for each hospital in each year it appeared in the source data. The remaining two datasets have one record per hospital: `pos_firstyear.dta` has only the record for the first year it appeared while `pos_lastyear.dta` has the record for the last year it appeared.

# Cautionary Notes!

* Hospitals that close will typically stay in the data in future years. The post-closure records should have a termination code (`termcode`) and termination date (`termdate`).
* Hospitals that merge, change subtype, or change type of control will usually get a new provider number. In this case, their old provider number will persist in the data but will get a termination code and date going forward. Keep this in mind when attempting to follow hospitals longitudinally. If you are lucky, the new hospital records will indicate the previous provider number (`prev_pn`). 
* I have heard, but can’t confirm, that CMS rarely updates this data, so the hospital characteristics in it may be quite out of date.
* The variables that count residents (`residents`) and beds (`beds_tot` and `beds_cert`) are very occasionally missing in 2011 and 2012. This issue seems to almost exclusively affect transplant hospitals.
* The variables that indicate the provider subtype e.g. short-term/long-term/etc. (`provider_subtype`) and type of control e.g. non-profit/for-profit/government (`typ_control`) are sometimes missing. This issue seems to be limited to certain transplant hospitals, federal hospitals like VA facilities, and Canadian hospitals. Note that indicators I derived from these variables (`shortterm`, `cah`, `nonprofit`, `forprofit`, `govt`) will be set to *zero* in this case.

# Download the processed data

I have put the processed Provider of Services data online at the below link:  
(Includes data in Stata v15, Stata v12, and CSV formats, plus full variable descriptions for those not using Stata.)

http://sacarny.com/public-files/provider-of-services/latest/provider-of-services.zip

# Instructions for processing the data yourself
1. Download the repository using the 'Clone or download' link on github, or clone this repository with the git command:
`git clone https://github.com/asacarny/provider-of-services.git`
1. Download the source data from NBER and put it into the `source/` subfolder. You have two options for this.
	1. Shell script: If you are on Mac/Linux/Cygwin, I made a shell script to download the files. Edit the file `download_source.sh` to set your start/end year and the method you'll use to retrieve the data (wget or rsync, though rsync will only work for those with an NBER username). Then open a terminal, `cd` to your repository folder, and run `bash download_source.sh`.
	2. By hand: Make a folder in the repository called `source/`. Go to http://www.nber.org/data/provider-of-services.html and download the Stata "Other" files in .dta format for the years you want. For *pre-2011* years, make sure to download the PROV links.
1. Edit the `pos.do` file so that the start/end years match the years of data you downloaded in the previous step.
1. Open stata, change its working directory to the repository, and run `do pos.do`
