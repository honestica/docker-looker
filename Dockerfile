FROM ubuntu:jammy-20230308

RUN apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get -y install --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    fontconfig \
    fonts-freefont-otf \
    git \
    gnupg \
    jq \
    libc6-dev \
    libfontconfig1 \
    mysql-client \
    netbase \
    openjdk-11-jre \
    python3 \
    python3-pip \
    tini \
    tzdata \
 && apt-get upgrade -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV PHANTOMJS_VERSION 2.1.1
ENV OPENSSL_CONF /etc/ssl
RUN curl -Ss --location -o- https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2 | tar -C /tmp -xjf- \
 && mv /tmp/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64/bin/phantomjs /usr/bin

ENV CHROME_VERSION 112.0.5615.49-1
RUN curl -Ss https://dl.google.com/linux/linux_signing_key.pub > /etc/apt/trusted.gpg.d/google-chrome.asc \
 && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update \
 && curl -Ss https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb -o /tmp/chrome.deb \
 && apt install --yes --no-install-recommends /tmp/chrome.deb \
 && rm /tmp/chrome.deb \
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

RUN chown -R looker:looker $HOME /home/looker

ENV PORT 9999
ENV LOOKERPORT 9999
EXPOSE 9999

ENV API_PORT 19999
EXPOSE 19999

ENV JMXARGS "-Dlog4j.formatMsgNoLookups=true -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.port=9910 -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.ssl=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.local.only=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.authenticate=true -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.access.file=$HOME/.lookerjmx/jmxremote.access -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.password.file=$HOME/.lookerjmx/jmxremote.password"
ENV JAVAARGS ""
ENV JAVAJVMARGS "-XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:MinRAMPercentage=50 -XX:MaxRAMPercentage=80"
ENV LOOKERARGS "--no-daemonize --log-format=json --no-log-to-file"
ENV LOOKEREXTRAARGS ""
ENV PROTOCOL "https"

USER looker

CMD exec tini -- assume_role_exec java $JAVAJVMARGS $JAVAARGS -jar $LOOKER_DIR/looker.jar start $LOOKERARGS $LOOKEREXTRAARGS
