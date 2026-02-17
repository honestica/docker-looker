FROM ubuntu:noble-20260113

RUN apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get -y install --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    libc6-dev \
    mysql-client \
    netbase \
    openjdk-11-jre \
    python3 \
    python3-pip \
    tini \
    tzdata \
 && apt-get upgrade -y \
 && apt-get clean

ENV PHANTOMJS_VERSION 2.1.1
ENV OPENSSL_CONF /etc/ssl
RUN curl -Ss --location -o- https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2 | tar -C /tmp --no-same-permissions -xjf- \
 && mv /tmp/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64/bin/phantomjs /usr/bin \
 && chmod +x /usr/bin/phantomjs

ENV MAVEN_VERSION 3.9.12
RUN curl -Ss --location -o- https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar -C /opt --no-same-permissions -xz \
 && ln -s /opt/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/bin/mvn

# Chromium dependencies
RUN apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get -y install --no-install-recommends \
    fontconfig \
    fonts-freefont-otf \
    fonts-liberation \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    libcairo2 \
    libcolord2 \
    libdatrie1 \
    libdeflate0 \
    libepoxy0 \
    libfontconfig1 \
    libfribidi0 \
    libgbm1 \
    libgdk-pixbuf-2.0-0 \
    libgdk-pixbuf2.0-common \
    libgtk-3-0 \
    libgtk-3-common \
    libjbig0 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpangoft2-1.0-0 \
    libpixman-1-0 \
    libthai-data \
    libthai0 \
    libtiff6 \
    libu2f-udev \
    libvulkan1 \
    libwayland-client0 \
    libwayland-cursor0 \
    libwayland-egl1 \
    libwayland-server0 \
    libwebp7 \
    libxcb-render0 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxinerama1 \
    libxkbcommon0 \
    libxrandr2 \
    python3-boto3 \
    shared-mime-info \
    ubuntu-mono \
    unzip \
    wget \
    xdg-utils \
    xkb-data \
 && apt-get clean

ENV CHROME_VERSION 97.0.4692.99-1
# Dirty fix due to unavailability of the upper chrome version
COPY chrome.deb /tmp/chrome.deb
RUN curl -Ss https://dl.google.com/linux/linux_signing_key.pub > /etc/apt/trusted.gpg.d/google-chrome.asc \
 && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update
RUN apt install --yes --no-install-recommends /tmp/chrome.deb \
 && apt-get clean

COPY chromium /usr/bin
RUN chmod +x /usr/bin/chromium

COPY assume_role_exec /usr/bin

RUN groupadd looker && useradd -m -g looker -s /bin/bash looker

ENV HOME /opt/looker
ENV LOOKER_DIR /opt/looker

RUN mkdir -p $HOME
RUN mkdir -p $LOOKER_DIR

WORKDIR $HOME

ARG LOOKER_VERSION
ENV LOOKER_VERSION $LOOKER_VERSION
COPY looker.jar $LOOKER_DIR
COPY looker-dependencies.jar $LOOKER_DIR
RUN update-alternatives --set java /usr/lib/jvm/java-11-openjdk-amd64/bin/java

ENV JMX_EXPORTER_VERSION 1.0.1
RUN mvn dependency:get \
    -DremoteRepositories=http://repo1.maven.org/maven2/ \
    -DgroupId=io.prometheus.jmx \
    -DartifactId=jmx_prometheus_javaagent \
    -Dversion=${JMX_EXPORTER_VERSION} \
    -Dtransitive=false \
 && mvn dependency:copy \
    -Dartifact=io.prometheus.jmx:jmx_prometheus_javaagent:${JMX_EXPORTER_VERSION} \
    -DoutputDirectory=$LOOKER_DIR \
 && mv $LOOKER_DIR/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar $LOOKER_DIR/jmx_prometheus_javaagent.jar
COPY jmx_prometheus_javaagent.yaml $LOOKER_DIR/jmx_prometheus_javaagent.yaml

RUN chown -R looker:looker $HOME /home/looker

ENV PORT 9999
ENV LOOKERPORT 9999
EXPOSE 9999

ENV API_PORT 19999
EXPOSE 19999

# unused, add it to JAVAARGS to set up JMX monitoring
ENV JMXARGS "-Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.port=9910 -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.ssl=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.local.only=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.authenticate=true -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.access.file=$HOME/.lookerjmx/jmxremote.access -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.password.file=$HOME/.lookerjmx/jmxremote.password"
# Disable javaagent by default, will be activable as an option in chart
# ENV JAVAARGS "-Dlog4j.formatMsgNoLookups=true -javaagent:$LOOKER_DIR/jmx_prometheus_javaagent.jar=8080:$LOOKER_DIR/jmx_prometheus_javaagent.yaml"
ENV JAVAARGS "-Dlog4j.formatMsgNoLookups=true"
ENV JAVAJVMARGS "-XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:MinRAMPercentage=50 -XX:MaxRAMPercentage=80"
ENV LOOKERARGS "--no-daemonize --log-format=json --no-log-to-file"
ENV LOOKEREXTRAARGS ""
ENV PROTOCOL "https"

USER looker
CMD exec tini -- assume_role_exec java $JAVAJVMARGS $JAVAARGS -jar $LOOKER_DIR/looker.jar start $LOOKERARGS $LOOKEREXTRAARGS
