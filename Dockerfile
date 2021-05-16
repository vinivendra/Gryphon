FROM swift:5.4


# Update, upgrade and install a few useful tools

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install unzip -y
RUN apt-get install zip -y
RUN apt-get install curl -y
RUN apt-get install wget -y


# Install Kotlin 1.3.61

### Inspired by https://hub.docker.com/r/jujhars13/docker-kotlin/~/dockerfile/
### and https://stackoverflow.com/questions/24085978/github-url-for-latest-release-of-the-download-file

RUN wget $(curl -s https://api.github.com/repos/JetBrains/kotlin/releases/latest | grep 'browser_download_url' | grep 'compiler' | cut -d\" -f4) -O /tmp/kotlin.zip && \
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

# Build with: docker build -t gryphon .
# Run with: docker run -it --rm --privileged -v /path/to/Gryphon/:/app/Gryphon gryphon
