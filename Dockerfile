FROM rocker/tidyverse:3.6.3

USER root

ENV APACHE_SPARK_VERSION 2.4.5
ENV HADOOP_VERSION 2.7

ENV USER_PERSISTED_VARS AWS_CONTAINER_CREDENTIALS_RELATIVE_URI AWS_DEFAULT_REGION AWS_EXECUTION_ENV AWS_REGION \
    ECS_CONTAINER_METADATA_URI S3_BUCKET USER KMS_HOME KMS_SHARED EMR_HOST_NAME

ENV R_DEPS devtools bestglm glmnet stringr tidyr V8
ENV R_PKGS bizdays boot cluster colorspace data.table deseasonalize DiagrammeR DiagrammeRsvg dplyr DT dyn feather \
flexdashboard forcats forecast ggplot2 googleVis Hmisc htmltools htmlwidgets intervals kableExtra knitr lazyeval \
leaflet lubridate magrittr manipulate maps networkD3 plotly plyr RColorBrewer readr reshape reshape2 reticulate \
rjson RJSONIO rmarkdown rmongodb RODBC scales shiny sparklyr sqldf stringr tidyr timeDate webshot xtable YaleToolkit zo \
aws.s3 aws.ec2metadata

RUN apt-get -y update  && apt-get install -y libcups2 libcups2-dev openjdk-11-jdk systemd python3 python3-pip \
    unixodbc-dev libbz2-dev libgsl-dev odbcinst libx11-dev mesa-common-dev libglu1-mesa-dev git-core s3fs \
    gdal-bin proj-bin libgdal-dev libproj-dev libudunits2-dev libtcl8.6 libtk8.6 libgtk2.0-dev stunnel && \
    apt-get clean

RUN pip3 install --upgrade git-remote-codecommit

RUN cd /tmp && \
    wget --no-verbose https://downloads.cloudera.com/connectors/impala_odbc_2.5.41.1029/Debian/clouderaimpalaodbc_2.5.41.1029-2_amd64.deb && \
    dpkg -i clouderaimpalaodbc_2.5.41.1029-2_amd64.deb && \
    odbcinst -i -d -f /opt/cloudera/impalaodbc/Setup/odbcinst.ini

RUN cd /tmp && \
    wget -q https://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

ENV SPARK_HOME /usr/local/spark
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info

RUN R -e "install.packages('sparklyr', repos='http://cran.rstudio.com/', dependencies=T)"

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

RUN for dep in ${R_DEPS}; do R -e "install.packages('${dep}')"; done

RUN for pkg in ${R_PKGS}; do R -e "install.packages('${pkg}')"; done

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
    echo "sed -i 's/REPLACEME/'\${EMR_HOST_NAME}'/g' /etc/skel/.spark_config.yml" >> /etc/cont-init.d/bootstrap_container && \
    chmod +x /etc/cont-init.d/bootstrap_container

RUN mkdir -p /etc/services.d/stunnel/ && \
    echo '#!/bin/bash' > /etc/services.d/stunnel/run && \
    echo 'exec stunnel' >> /etc/services.d/stunnel/run && \
    sed -i '2iUSERID=\$(/usr/bin/shuf -i 1001-30000 -n 1)' /etc/cont-init.d/userconf

ADD user_spark_config.yml /etc/skel/.spark_config.yml
ADD Rprofile.user /etc/skel/.Rprofile

CMD ["/init"]
