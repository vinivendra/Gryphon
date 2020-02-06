FROM swift:latest


# Update, upgrade and install a few useful tools

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install unzip -y
RUN apt-get install zip -y
RUN apt-get install curl -y
RUN apt-get install wget -y


# Install Kotlin 1.3.61

### From https://hub.docker.com/r/jujhars13/docker-kotlin/~/dockerfile/
ENV VERSION 1.3.61
ENV KOTLIN_URL https://github.com/JetBrains/kotlin/releases/download/v${VERSION}/kotlin-compiler-${VERSION}.zip
RUN wget ${KOTLIN_URL} -O /tmp/kotlin.zip && \
    unzip /tmp/kotlin.zip -d /opt && \
    rm /tmp/kotlin.zip
ENV PATH $PATH:/opt/kotlinc/bin


# Install Java 8

### From https://stackoverflow.com/questions/36587850/best-way-to-install-java-8-using-docker
RUN apt-get install -y --no-install-recommends software-properties-common
RUN add-apt-repository -y ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get install -y openjdk-8-jdk
RUN apt-get install -y openjdk-8-jre
RUN update-alternatives --config java
RUN update-alternatives --config javac


# Set the working directory

WORKDIR /app/Gryphon

# Build with: docker build -t swift_ubuntu .
# Run with: docker run -it --rm --privileged -v /path/to/Gryphon:/app/Gryphon swift_ubuntu
