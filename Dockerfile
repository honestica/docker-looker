FROM ubuntu:jammy-20230624

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
RUN curl -Ss --location -o- https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2 | tar -C /tmp -xjf- \
 && mv /tmp/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64/bin/phantomjs /usr/bin

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
    libtiff5 \
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
    shared-mime-info \
    ubuntu-mono \
    unzip \
    wget \
    xdg-utils \
    xkb-data \
 && apt-get clean

ENV CHROME_VERSION 97.0.4692.99-1
# Dirty fix due to unavailability of the upper chrome version
COPY --from=honestica/looker:23.6.77-efe426d1f137a8931288ed547cdf89a3a5c13008 /tmp/chrome.deb /tmp/chrome.deb
RUN curl -Ss https://dl.google.com/linux/linux_signing_key.pub > /etc/apt/trusted.gpg.d/google-chrome.asc \
 && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update
RUN apt install --yes --no-install-recommends /tmp/chrome.deb \
 && apt-get clean

COPY chromium /usr/bin
RUN chmod +x /usr/bin/chromium

RUN pip3 install boto3==1.24.20
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

ENV JMX_EXPORTER_VERSION 0.19.0
RUN curl https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$JMX_EXPORTER_VERSION/jmx_prometheus_javaagent-$JMX_EXPORTER_VERSION.jar -o $LOOKER_DIR/jmx_prometheus_javaagent.jar
COPY jmx_prometheus_javaagent.yaml $LOOKER_DIR/jmx_prometheus_javaagent.yaml

RUN chown -R looker:looker $HOME /home/looker

ENV PORT 9999
ENV LOOKERPORT 9999
EXPOSE 9999

ENV API_PORT 19999
EXPOSE 19999

# unused, add it to JAVAARGS to set up JMX monitoring
ENV JMXARGS "-Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.port=9910 -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.ssl=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.local.only=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.authenticate=true -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.access.file=$HOME/.lookerjmx/jmxremote.access -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.password.file=$HOME/.lookerjmx/jmxremote.password"
ENV JAVAARGS "-Dlog4j.formatMsgNoLookups=true -javaagent:$LOOKER_DIR/jmx_prometheus_javaagent.jar=8080:$LOOKER_DIR/jmx_prometheus_javaagent.yaml"
ENV JAVAJVMARGS "-XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:MinRAMPercentage=50 -XX:MaxRAMPercentage=80"
ENV LOOKERARGS "--no-daemonize --log-format=json --no-log-to-file"
ENV LOOKEREXTRAARGS ""
ENV PROTOCOL "https"

USER looker

CMD exec tini -- assume_role_exec java $JAVAJVMARGS $JAVAARGS -jar $LOOKER_DIR/looker.jar start $LOOKERARGS $LOOKEREXTRAARGS
