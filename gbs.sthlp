{smcl}
{* 11nov2025}{...}
{hi:help gbs}
{hline}

{title:Title}

{pstd}{hi:gbs} {hline 2} Generalized bootstrap

{title:Syntax}

{p 8 15 2}
{cmd:gbs} {ifin}, {cmd:expression}(string) {cmd:weight}(varname) [{cmd:}
{help gbs##comopt:{it:options}}
 ] : command

{synoptset 25 tabbed}{...}
{marker comopt}{synopthdr:options}
{synoptline}
{synopt :{opt expression(string)}}An {help exp_list} to be passed to the gbs command (mandatory)
  {p_end}
{synopt :{opt weight(varname)}}A variable containing the (sampling) weights for each observation (mandatory)
  {p_end}
{synopt :{opt reps(#)}}perform # bootstrap replications; default is {cmd: reps(100)}
  {p_end}
{synopt :{opt seed(#)}}set the random-number seed (must match the number of threads)
  {p_end}
{synopt :{opt level(#)}}set confidence level; default is {cmd: level(95)}
  {p_end}
{synopt :{opt graph}}display a graph showing bootstrap distribution(s)
  {p_end}
{synopt :{opt format(%fmt)}}display format for results
  {p_end}
{synopt :{opt parallel(#)}}number of threads to use; default is {cmd: parallel(1)}
  {p_end}
{synopt :{opt cluster(varlist)}}variables identifying resampling clusters
  {p_end}
{synopt :{opt idcluster(varname)}}creates a new cluster ID variable
  {p_end}
{synopt :{opt strata(varname)}}variable identifying strata
  {p_end}
{synopt :{opt saving(filename, ...)}}save results to a file
  {p_end}
{synopt :{opt rround}}use random rounding for sample sizes across strata
  {p_end}
{synopt :{opt noisily}}display more output
  {p_end}
{synopt :{opt noadjust}}do not adjust confidence intervals
  {p_end}

{title:Description}

{pstd}{cmd:gbs} implements generalized bootstrapping. In contrast to
the regular {help bootstrap:{it:bootstrap}}, this approach allows
for unequal sampling probabilities. This means that the probability
of being selected into a bootstrap resample can differ across observations
and is determined by the specified weight variable, which is mandatory.
Enabling unequal probability sampling (UPS) makes bootstrapping more
flexible and suitable for a wider range of applications. The command generates both
normal-based and percentile confidence intervals. A working paper describing {cmd:gbs}
in detail is available; see Bittmann (2025).

{pstd} This command depends on {help gsample:{it:gsample}} and
{help parallel:{it:parallel}}, which must be installed before use.

{title:Options}

{marker comoptd}{it:{dlgtab:required}}

{phang}{opt expression(string)} specifies the list of coefficients or statistics to bootstrap. 
To determine how other Stata commands return these values, type {cmd:return list} or {cmd:ereturn list} 
after executing the command of interest. Estimation results are often stored in a matrix called {cmd:r(table)}.

{phang}{opt weight(varname)} specifies the variable containing the sampling weights for each observation.

{marker comoptd}{it:{dlgtab:optional}}

{phang}{opt reps(#)} specifies the number of bootstrap resamples to be drawn. 
Larger values produce more precise results but require longer computation times. 
For initial testing, as few as 100 replications may suffice, whereas 500 to 1,000 or more are generally recommended. 
Using multiple threads (see {opt parallel}) can speed up computation. 
Examining the bootstrap distribution (see {opt graph}) can help assess whether a sufficient number of resamples was used.

{phang}{opt seed(#)} sets the random-number seed. 
Because bootstrapping relies on random sampling, results may vary even with identical data. 
Setting a seed ensures reproducibility. When using more than one thread (see {opt parallel}), 
the number of seeds specified must match the number of threads.

{phang}{opt level(#)} sets the confidence level; see {help estimation options##level()}.

{phang}{opt graph} displays a histogram of the final bootstrap distribution for each statistic of interest.
Ideally, these distributions are smooth and approximately normal. If not, consider increasing the number of resamples.
If the distribution remains irregular, bootstrapping may not be appropriate for the statistic in question.

{phang}{opt parallel(#)} specifies the number of threads to use in computation.
Using more threads generally increases speed but depends on system capacity.
Setting a value higher than the available number of threads may cause instability or crashes.
For details, see {help parallel}.

{phang}{opt cluster(varlist)} identifies sampling clusters (i.e., primary sampling units). 
If {cmd:cluster()} is specified, the sample is drawn by clusters. 
Cluster variables may be numeric or string. 
{cmd:The weights must be constant within each cluster.}

{phang}{opt idcluster(varname)} creates a new variable containing a unique identifier for each
resampled cluster. This option requires that {opt cluster()} also be specified.

{phang}{opt strata(varname)} identifies stratification variables. 
If {cmd:strata()} is specified, samples are drawn within each stratum. 
The strata variables may be numeric or string.

{phang}{opt saving(filename)} creates a Stata data file (.dta) containing, for each statistic 
specified in {opt expression()}, a variable with the corresponding bootstrap replicates.

{phang}{opt rround} applies random rounding to non-integer sample sizes across strata; 
see {help gsample} for details.

{phang}{opt noisily} displays more detailed output.

{phang}{opt noadjust} specifies that reported confidence intervals should not be adjusted.
Note that in generalized bootstrapping with unequal sampling probabilities, 
observations with larger weights have a higher probability of inclusion in a resample. 
As a result, the generated resamples tend to show less variation than the original sample.
While this has little effect on point estimates, it underestimates variances, 
producing confidence intervals that are too narrow and therefore liberal.
This can lead to an increased likelihood of rejecting the null hypothesis. 
To mitigate this effect, {cmd:gbs} applies an adjustment factor that widens the intervals 
based on the coefficient of variation of the weight variable.

{title:Examples}

{dlgtab:Installing dependencies}

{p 8 12 2}. {stata "ssc install gsample, replace"}{p_end}
{p 8 12 2}. {stata "ssc install moremata, replace"}{p_end}
{p 8 12 2}. {stata "net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace"}{p_end}
{p 8 12 2}. {stata "mata mata mlib index"}{p_end}

{dlgtab:Spearman's rho with sampling weights}

{p 8 12 2}. {stata "webuse nhanes2, clear"}{p_end}
{p 8 12 2}. {stata "replace hlthstat = .a if hlthstat == 8"}{p_end}
{p 8 12 2}. {stata "gbs, expression(rho=r(rho)) weight(finalwgt): spearman hlthstat hsizgp"}{p_end}

{dlgtab:Linear (OLS) regression}

{p 8 12 2}. {stata "webuse nhanes2, clear"}{p_end}
{p 8 12 2}. {stata "regress bpsystol age bmi diabetes [pweight=finalwgt]"}{p_end}
{p 8 12 2}. {stata "gbs, expression(age=r(table)[1,1]) weight(finalwgt): regress bpsystol age bmi diabetes"}{p_end}

{title:Returned results}

{pstd}Scalars:

{p2colset 5 20 20 2}{...}
{p2col : {cmd:e(N)}}number of observations{p_end}
{p2col : {cmd:e(reps)}}number of bootstrap replications{p_end}
{p2col : {cmd:e(threads)}}number of threads used{p_end}
{p2col : {cmd:e(runtime)}}elapsed computation time{p_end}

{pstd}Macros:

{p2col : {cmd:e(weight)}}weight variable{p_end}
{p2col : {cmd:e(strata)}}strata variable (if specified){p_end}

{pstd}Matrices:

{p2col : {cmd:e(table)}}all coefficients and confidence intervals{p_end}

{title:References}

{phang}Bittmann, F. (2025). {it:Generalized bootstrapping as an alternative to classical weighting approaches.} 
https://doi.org/10.5281/zenodo.17581255

{phang}Jann, B. (2020). {it:gsample.} Stata module for random sampling. https://github.com/benjann/gsample

{phang}Vega Yon, G. G., & Quistorff, B. (2019). {it:parallel: A command for parallel computing.} 
The Stata Journal, 19(3), 667–684. doi:10.1177/1536867X19874242

{title:Author}

{pstd}Felix Bittmann, Leibniz Institute for Educational Trajectories (LIfBi), felix.bittmann@lifbi.de

{pstd}Please cite this software as follows:

{pmore}
Bittmann, F. (2025). {it:gbs: Generalized bootstrap.} Available from https://github.com/fbittmann/gbs

{title:Also see}

{helpb bootstrap}, {helpb gsample}, {helpb parallel}

