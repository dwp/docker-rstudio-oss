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
R -e "install.packages(c(${PCK}), repos='https://cran.rstudio.com/', dependencies=TRUE, Ncpus=parallel::detectCores(), quiet=TRUE)"
