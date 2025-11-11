# gbs
Stata module for generalized bootstrapping

`gbs` performs generalized bootstrapping in Stata. For details and more examples, see the
working paper here: https://doi.org/10.5281/zenodo.17581255

To install `gbs`, type

    . net install gbs, replace from(https://raw.githubusercontent.com/fbittmann/gbs/main/)

To install all required dependencies, type

    . ssc install gsample, replace
    . ssc install moremata, replace
    . net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace
    . mata mata mlib index

Minimal example

    . webuse nhanes2, clear
    . replace hlthstat = .a if hlthstat == 8
    . gbs, expression(rho=r(rho)) weight(finalwgt): spearman hlthstat hsizgp

---

Main changes:

    11nov2025
    - first released on Github


