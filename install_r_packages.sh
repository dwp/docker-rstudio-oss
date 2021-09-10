#!/bin/bash

set -euo pipefail

PCK=""
for i in ${R_DEPS[@]}; do
    PCK="${PCK}'${i}',"; 
done;
for i in ${R_PKGS[@]}; do
    PCK="${PCK}'${i}',"; 
done;

PCK="${PCK%?}"; # Remove last comma

# issue a standard single command to install all *user requested* pkgs
R -e "install.packages(c(${PCK}), repos='https://cran.rstudio.com/', dependencies=TRUE, Ncpus=parallel::detectCores(), quiet=TRUE)"

# check if all the *user requested* pkgs are installed successfully or not
# convert string pkg var defined earlier into an array
declare -a PKGS=($(echo "${PCK}" | sed 's/\x27//g'| tr "," "\n"))
# store output of in-built function `find.package()` when a pacakge is not found, into a var to compare later
PKG_FAILED_STATUS="character(0)"
# loop through all *user requested* pkgs
for p in "${PKGS[@]}";
do
    # store only line 2 from the output
    PKG_STATUS=$(R -q -e "find.package(\"${p}\", quiet=TRUE, verbose=TRUE)" | sed -n 2p)
    if [ "${PKG_STATUS}" == "${PKG_FAILED_STATUS}" ]; then
        # install using `devtools` when a package found that was missed using standard install function
        R -e "require(devtools); install_version('"${p}"', repos='http://cran.rstudio.com/', dependencies=T, Ncpus=parallel::detectCores(), quiet=TRUE)"
    fi
done

# always leave `sparklyr` package as last step to stop it getting updated accidently as dependency for some other pkg
# and pin sparklyr version to 1.6.2
R -e "require(devtools); install_version('sparklyr', version = '1.6.2', repos='http://cran.rstudio.com/', dependencies=T, Ncpus=parallel::detectCores(), quiet=TRUE)"
