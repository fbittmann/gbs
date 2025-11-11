program define gbs, eclass
	*! version 1.0.0  11nov2025  Felix Bittmann
	
	*** Checking for ados ***
	timer clear 39
	timer on 39
	
	cap which gsample 
	if _rc != 0 {
		di as error "gsample not found. Please install this required package first. Type:"
		di as error "ssc install gsample, replace"
		exit 111
		}
		
	cap which parallel 
	if _rc != 0 {
		di as error "parallel not found. Please install this required package first. See:"
		di as error "https://github.com/gvegayon/parallel""
		exit 111
		}

	*** Parsing main command ***
	gettoken leftside command : 0, parse(":")
	local command = strltrim(subinstr("`command'", ":", "", 1))
	local 0: copy local leftside	
	*di `leftside'
	*di `command'	

	syntax [if] [in], ///
		EXPression(string) ///
		Weight(varname) ///
		[reps(integer 100)] ///
		[seed(passthru)] ///
		[level(real 95)] ///
		[graph] ///
		[dots(integer 10)] ///
		[format(string)] ///
		[PARallel(integer 1)] ///
		[cluster(passthru)] ///
		[idcluster(varlist)] ///
		[strata(passthru)] ///
		[saving(string)] ///
		[rround] ///
		[noadjust] ///
		[NOISily]
		
	*** Parsing coefs ***
	local counter = 1
	local cnames
	local cvalues
	foreach element of local expression {
		if strpos("`element'", "=") > 1 {
			gettoken name value : element, parse("=")
			local cnames `cnames' `name'
			local res = subinstr("`value'", "=", "", 1)
			local cvalues `cvalues' `res'
		} 
		else {
			local cnames `cnames' _sim_`counter'
			local cvalues `cvalues' `element'
		}
	local ++counter	
	}

	tempfile orig_data123		//Store original dataset
	qui save `orig_data123'

	*** Restricting the sample if specified (IDK why 'marksample touse' gives an error)
	if "`if'" != "" {
		keep `if'
	}
	if "`in'" != "" {
		keep `in'
	}
	
	*** Testing N ***
	ereturn clear
	qui `noisily' `command'
	local N = e(N)
	tempvar samp111
	generate `samp111' = e(sample)
	if `N' > 1 & !missing(`N') {
		qui `noisily' keep if `samp111' == 1
	}
	else {
		di as text "warning: the specified command does not set e(sample),"
		di "so no observations will be excluded from the resampling"
		di "because of missing values or other reasons. To exclude"
		di "observations, press Break, save the data, drop any"
		di "observations that are to be excluded, and rerun gbs."
		di ""
		di ""
	}	
	cap drop `idcluster'
	qui sum `weight'
	local cv = r(sd) / r(mean)	//Compute coefficient of variation for adjustment
	
	local coeflist
	local counter = 1
	foreach element of local cvalues {
		local coeflist `coeflist' r(c`counter')
		local ++counter
	}
	
	*** Bootstrap in parallel ***
	quiet `noisily' parallel init `parallel', force
	quiet `noisily' parallel sim, expr(`coeflist') reps(`reps') `seed': ///
		gbs_sampler, command(`command') weight(`weight') ///
		coefs(`cvalues') `cluster' idcluster(`idcluster') `rround'
		
	qui rename (_all) (`cnames')
	foreach VAR of varlist _all {
		label var `VAR' "`VAR'"
	}
	if "`saving'" != "" {			//save dataset
		qui save `saving'
	}

	*** Alpha limits ***
	local limlower = (100 - `level') / 2
	local limupper = 100 - `limlower'
	
	tempname name
	tempfile file
	postfile `name' str16 stat mean median lower upper str12 type using `file'
	local counter = 1
	foreach VAR of varlist _all {
		qui sum `VAR', det
		local mean = r(mean)
		local median = r(p50)
		local sd = r(sd)
		local df = r(N) - 1
		local limit = invttail(`df', `=`limlower'/100')
		qui centile `VAR', centile(`limlower' `limupper')
		post `name' ("`VAR'") (`mean') (`median') (`r(c_1)') (`r(c_2)') ///
			("perc.")
		local cilower = `mean' - `limit' * `sd'
		local ciupper = `mean' + `limit' * `sd'
		post `name' ("`VAR'") (.) (.) (`cilower') (`ciupper') ///
			("norm.")
			
		if "`graph'" == "graph" {
			qui histogram `VAR', name(g`counter', replace) ytitle("") ///
				nodraw normal
			local allgraphs `allgraphs' g`counter'
		}
		local ++counter
	}
	postclose `name'
	
	*** Display results ***
	use `file', clear
	if "`adjust'" == "" {		//implement correction factor for too short CIs
		qui replace lower = lower - abs(lower * `cv' * 0.10)
		qui replace upper = upper + abs(upper * `cv' * 0.10)
	}
	
	if "`format'" != "" {
		format `format' mean median lower upper		
	}
	*rename varname stat
	list, noobs sep(0)
	mkmat mean - upper, matrix(table)
	local ncoefs = `:word count `cvalues''
	local nn
	forvalues i = 1/`ncoefs' {
		local w : word `i' of `cnames'
		local nn `nn' `w' `w'
	}
	matrix rownames table = `nn'
	di "Note: Normal CIs are based on the mean. CI level: `level'% based on `reps' resamples"	
	
	*** Display graph ***
	if "`graph'" == "graph" {
		graph combine `allgraphs'
	}
	qui use `orig_data123', clear		//Restore to original
	timer off 39
	qui timer list 39
	local runtime = r(t39)
	
	*** Return values ***
	ereturn clear
	ereturn scalar N = `N'
	ereturn scalar reps = `reps'
	ereturn scalar threads = `parallel'
	ereturn scalar runtime = `runtime'
	
	ereturn local strata `strata'
	ereturn local cluster `cluster'
	ereturn local weight `weight'
	ereturn local seed `seed'
	ereturn matrix table = table
end
