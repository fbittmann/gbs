program define gbs_sampler, rclass
	syntax, command(string) ///
		weight(varname) ///
		coefs(string) ///
		[cluster(passthru)] ///
		[idcluster(passthru)] ///
		[strata(passthru)] ///
		[rround]
	preserve
	gsample [iweight=`weight'], `cluster' `idcluster' `strata' `rround'	//bootstrap resample
	`command'
	local counter = 1
	foreach element of local coefs {
		return scalar c`counter' = `element'
		local ++counter
	}
	restore	
end
