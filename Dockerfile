FROM rocker/r-ver:3.5.3 as install_stage

RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    xtail \
    wget \
    python \
    git

FROM install_stage as shiny_install
# Download and install shiny server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    . /etc/environment && \
    R -e "install.packages(c('shiny', 'rmarkdown', 'gh'), repos='$MRAN')" && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ && \
    chown shiny:shiny /var/lib/shiny-server

# Modify server conf and download app
FROM shiny_install as mod_conf
COPY scripts/mod_conf.py /etc/shiny-server/
RUN python /etc/shiny-server/mod_conf.py && \
    rm -rf /srv/shiny-server/* && \
    git clone https://github.com/federicomarini/ideal_serveredition.git /srv/shiny-server/ideal/

#Install ideal
FROM mod_conf as ideal_install
RUN apt-get install -y libssl-dev libxml2-dev && \
    R -e "source('http://bioconductor.org/biocLite.R')" && \
    R -e "BiocInstaller::biocLite('devtools')" && \
    R -e "BiocInstaller::biocLite('federicomarini/ideal')"

from ideal_install as db_installs
RUN R -e "BiocInstaller::biocLite('org.Mm.eg.db')"

FROM db_installs as run_server

EXPOSE 3838
COPY shiny-server.sh /usr/bin/shiny-server.sh
CMD ["/usr/bin/shiny-server.sh"]
