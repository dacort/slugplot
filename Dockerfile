FROM amazoncorretto:8

RUN yum -y update
RUN amazon-linux-extras install R4

RUN yum -y install \
    cairo-devel \
    hostname \
    libxml2-devel \
    openssl-devel  \
    libcurl-devel

# Setup a CRAN mirror
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile

# Install Rust for gifski for gganimate
ENV CARGO_HOME=/cargo
ENV RUSTUP_HOME=/rustup
RUN curl https://sh.rustup.rs -sSf \
    | sh -s -- -y --default-toolchain 1.51.0

ENV PATH="$PATH:/cargo/bin"

# install packages and check installation success, install.packages itself does not report fails
# thank you https://stackoverflow.com/a/65401418/5141922
RUN Rscript -e "install.packages('ggridges');                           if (!library(ggridges, logical.return=T)) quit(status=10)" \
    && Rscript -e "install.packages('hrbrthemes',dependencies=TRUE);       if (!library(hrbrthemes, logical.return=T)) quit(status=10)" \
    && Rscript -e "install.packages('viridis',dependencies=TRUE);          if (!library(viridis, logical.return=T)) quit(status=10)" \
    && Rscript -e "install.packages('IRdisplay');                             if (!library(IRdisplay, logical.return=T)) quit(status=10)" \
    && Rscript -e "install.packages('gifski');                             if (!library(gifski, logical.return=T)) quit(status=10)" \
    && Rscript -e "install.packages('gganimate');                          if (!library(gganimate, logical.return=T)) quit(status=10)" \
    && Rscript -e "install.packages('aws.ec2metadata');                    if (!library(aws.ec2metadata, logical.return=T)) quit(status=10)" \
    && Rscript -e "install.packages('aws.s3');                             if (!library(aws.s3, logical.return=T)) quit(status=10)"