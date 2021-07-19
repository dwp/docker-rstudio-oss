FROM rocker/tidyverse:3.6.3

USER root

ENV HADOOP_VERSION 2.7

ENV USER_PERSISTED_VARS AWS_CONTAINER_CREDENTIALS_RELATIVE_URI AWS_DEFAULT_REGION AWS_EXECUTION_ENV AWS_REGION \
    ECS_CONTAINER_METADATA_URI S3_BUCKET USER KMS_HOME KMS_SHARED HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy JWT_TOKEN SPARK_VERSION S3_HOME_PATH

ENV R_DEPS devtools bestglm glmnet stringr tidyr V8 dplyr
ENV R_PKGS bizdays boot cluster colorspace data.table deseasonalize DiagrammeR DiagrammeRsvg dplyr DT dyn feather \
flexdashboard forcats forecast ggplot2 googleVis Hmisc htmltools htmlwidgets intervals kableExtra knitr lazyeval \
leaflet lubridate magrittr manipulate maps networkD3 plotly plyr RColorBrewer readr reshape reshape2 reticulate \
rjson RJSONIO rmarkdown odbc scales shiny sqldf timeDate webshot xtable YaleToolkit zoo \
aws.s3 aws.ec2metadata logging zip xlsx openxlsx svDialogs janitor rapportools leaflet.extras NCmisc ggalluvial \
pacman bupaR distill blogdown pkgdown ggrepel rms filesstrings cowplot anytime flexdashboard dygraphs ISOweek gdata \
Benchmarking DiceKriging DiceOptim eventdataR formattable ggiraph gtools heuristicsmineR lhs maditr NLP pheatmap \
processanimateR processmapR processmonitR qdap RColourBrewer readxl rgdal shinydashboard syuzhet textclean \
textreuse tictoc tidytext TM topicmodels wordcloud xesreadR sparklyr stringi PM4Py rsvg gifski RQuantLib magick SGP


RUN apt-get -y update  && apt-get install -y libcups2 libcups2-dev openjdk-11-jdk systemd python3 python3-pip \
    unixodbc libbz2-dev libgsl-dev odbcinst libx11-dev mesa-common-dev libglu1-mesa-dev git-core texlive-latex-base \
    texlive-fonts-recommended texlive-latex-recommended texlive-latex-extra gdal-bin proj-bin libgdal-dev libproj-dev \
    libudunits2-dev libtcl8.6 libtk8.6 libgtk2.0-dev stunnel vim libv8-dev librsvg2-dev libmagick++-dev libavformat-dev \
    libpoppler-cpp-dev && \
    apt-get clean

RUN pip3 install --upgrade git-remote-codecommit

COPY install_r_packages.sh /opt/
RUN chmod +x /opt/install_r_packages.sh && /opt/install_r_packages.sh

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

COPY install_local_packages.r /opt/install_local_packages.r

# Be sure rstudio user has full access to their home directory
RUN mkdir -p /home/rstudio && \
  chown -R rstudio:rstudio /home/rstudio && \
  chmod -R 755 /home/rstudio

ENV PATH=$JAVA_HOME/bin:$PATH

ENV DEBIAN_FRONTEND noninteractive

ADD stunnel.conf /etc/stunnel/stunnel.conf

RUN echo "#!/bin/bash" > /etc/cont-init.d/gen-certs && \
    echo "/usr/bin/openssl req -x509 -newkey rsa:4096 -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem -days 30 -nodes -subj '/CN=rstudio'" >> /etc/cont-init.d/gen-certs && \
    chmod +x /etc/cont-init.d/gen-certs

RUN echo "#!/usr/bin/with-contenv bash" > /etc/cont-init.d/bootstrap_container && \
    for var in ${USER_PERSISTED_VARS}; do echo "echo \"${var}=\${${var}}\" >> /usr/local/lib/R/etc/Renviron" >> /etc/cont-init.d/bootstrap_container; done && \
    echo "echo \"r-libs-user=/home/\${USER}/.rpckg\" >> /etc/rstudio/rsession.conf" >> /etc/cont-init.d/bootstrap_container && \
    echo "sed -i '/^R_LIBS_USER=/c\\R_LIBS_USER=/home/'\${USER}'/.rpckg' /usr/local/lib/R/etc/Renviron" >> /etc/cont-init.d/bootstrap_container && \
    echo "sed -i 's#HOST=#HOST='\${EMR_HOST_NAME}'#g' /etc/odbc.ini" >> /etc/cont-init.d/bootstrap_container && \
    echo "sed -i 's#REPLACEME#'\${LIVY_URL}'#g' /etc/skel/.spark_config.yml" >> /etc/cont-init.d/bootstrap_container && \
    chmod +x /etc/cont-init.d/bootstrap_container && \
    sed -i 's?cp -r /home/rstudio .*?ln -s /mnt/s3fs/s3-home /home/\$USER?' /etc/cont-init.d/userconf && \
    sed -i '/useradd -m $USER -u $USERID/,/mkdir/c\
\    \# Link S3 home directory instead of creating directory.\n\
    \# and add missing skeleton files\n\
    useradd -M $USER -u $USERID\n\
    ln -s /mnt/s3fs/s3-home /home/$USER\n\
    for f in `ls -1A /etc/skel`\n\
    do\n\
      cp -n /etc/skel/$f /home/$USER\n\
      chown $USER /home/$USER/$f\n\
    done\n\
\    \# special case for config files\n\
    cp -f /etc/skel/.spark_config.yml /home/$USER\n\
    chown $USER /home/$USER/.spark_config.yml\n\
\   \# Install local packages\n\
    Rscript /opt/install_local_packages.r\n\
    \# End of changes\n\
' /etc/cont-init.d/userconf && \
    chmod +x /etc/cont-init.d/userconf

RUN mkdir -p /etc/services.d/stunnel/ && \
    echo '#!/bin/bash' > /etc/services.d/stunnel/run && \
    echo 'exec stunnel' >> /etc/services.d/stunnel/run && \
    sed -i '2iUSERID=\1001' /etc/cont-init.d/userconf && \
    echo "for f in \$(find /home/\$USER/.rstudio -name '*.env'); do for USER_PERSISTED_VAR in \${USER_PERSISTED_VARS}; do sed -i \"/\$USER_PERSISTED_VAR/d\" \$f; done; done" >> /etc/cont-init.d/userconf

ADD user_spark_config.yml /etc/skel/.spark_config.yml
ADD helpers.r /opt/helpers.r
ADD init.r /opt/init.r
RUN echo "source(\"/opt/init.r\");source(\"/opt/helpers.r\");" >> /usr/local/lib/R/etc/Rprofile.site

ADD amazonhiveodbc_2.6.9.1009-2_amd64.deb /opt/dataworks/hiveodbc.deb
RUN dpkg -i /opt/dataworks/hiveodbc.deb \
    && rm -rf /opt/dataworks/hiveodbc.deb

COPY odbc*.ini /etc/

CMD ["/init"]
