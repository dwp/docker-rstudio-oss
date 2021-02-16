#!/bin/bash

set -euo pipefail

R -e "install.packages('sparklyr', repos='http://cran.rstudio.com/', dependencies=T, Ncpus=parallel::detectCores(), quiet=TRUE)"

PCK=""
for i in ${R_DEPS[@]}; do
    PCK="${PCK}'${i}',"; 
done;
for i in ${R_PKGS[@]}; do
    PCK="${PCK}'${i}',"; 
done;

PCK="${PCK%?}"; # Remove last comma

R -e "install.packages(c(${PCK}), repos='https://cran.rstudio.com/', Ncpus=parallel::detectCores(), quiet=TRUE)"
