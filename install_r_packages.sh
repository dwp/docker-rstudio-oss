#!/bin/bash

set -euo pipefail

# pin sparklyr version to 1.6.2
R -e "install.packages('sparklyr', version = '1.6.2', repos='http://cran.rstudio.com/', dependencies=T, Ncpus=parallel::detectCores(), quiet=TRUE)"

PCK=""
for i in ${R_DEPS[@]}; do
    PCK="${PCK}'${i}',"; 
done;
for i in ${R_PKGS[@]}; do
    PCK="${PCK}'${i}',"; 
done;

PCK="${PCK%?}"; # Remove last comma
R -e "install.packages(c(${PCK}), repos='https://cran.rstudio.com/', dependencies=TRUE, Ncpus=parallel::detectCores(), quiet=FALSE)"
