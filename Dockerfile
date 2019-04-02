FROM swift:latest


# Update, upgrade and install a few useful tools

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install unzip -y
RUN apt-get install zip -y
RUN apt-get install curl -y
RUN apt-get install wget -y


# Install Kotlin 1.2.31

### From https://hub.docker.com/r/jujhars13/docker-kotlin/~/dockerfile/
ENV VERSION 1.2.31
ENV KOTLIN_URL https://github.com/JetBrains/kotlin/releases/download/v${VERSION}/kotlin-compiler-${VERSION}.zip
RUN wget ${KOTLIN_URL} -O /tmp/kotlin.zip && \
    unzip /tmp/kotlin.zip -d /opt && \
    rm /tmp/kotlin.zip
ENV PATH $PATH:/opt/kotlinc/bin


# Install Java 8

### From https://stackoverflow.com/questions/48301257/how-to-install-oracle-java8-installer-on-docker-debianjessie
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >> /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN echo "debconf shared/accepted-oracle-license-v1-1 select true" | /usr/bin/debconf-set-selections
RUN apt-get update
RUN apt-get install -y --force-yes vim
RUN apt-get install -y --force-yes oracle-java8-installer


# Set the working directory

WORKDIR /app/Gryphon

# Build with: docker build -t swift_ubuntu .
# Run with: docker run -it --rm --privileged -v /path/to/Gryphon:/app/Gryphon swift_ubuntu
