FROM ubuntu:20.04

RUN apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get -y install --no-install-recommends \
    ca-certificates \
    curl \
    fonts-freefont-otf \
    git \
    gnupg \
    jq \
    libc6-dev \
    libfontconfig1 \
    mysql-client \
    openjdk-11-jre \
    phantomjs \
    tini \
    tzdata \
 && apt-get upgrade -y \
 && apt-get clean

RUN curl https://dl.google.com/linux/linux_signing_key.pub | apt-key add \
 && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get -y install --no-install-recommends \
    google-chrome-stable \
 && ln -s /usr/bin/google-chrome /usr/bin/chromium \
 && apt-get clean

RUN groupadd looker && useradd -m -g looker -s /bin/bash looker

ENV HOME /opt/looker
ENV LOOKER_DIR /opt/looker

# Minor version should be still valid or the build will failed, get the last
# from the download page https://download.looker.com/
ENV LOOKER_VERSION 7.20.29

RUN mkdir -p $HOME
RUN mkdir -p $LOOKER_DIR

WORKDIR $HOME

ARG LICENSE
ARG EMAIL
RUN echo $LICENSE
RUN curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'"$LICENSE"'", "email": "'"$EMAIL"'", "latest": "specific", "specific": "looker-'"$LOOKER_VERSION"'.jar"}' https://apidownload.looker.com/download > api_response.json \
  && cat api_response.json && curl "$(cat api_response.json | jq -r '.url')" -o $LOOKER_DIR/looker.jar \
  && curl "$(cat api_response.json | jq -r '.depUrl')" -o $LOOKER_DIR/looker-dependencies.jar

RUN chown -R looker:looker $HOME

ENV PORT 9999
ENV LOOKERPORT 9999
EXPOSE 9999

ENV API_PORT 19999
EXPOSE 19999

ENV JMXARGS "-Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.port=9910 -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.ssl=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.local.only=false -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.authenticate=true -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.access.file=$HOME/.lookerjmx/jmxremote.access -Dcom.sun.akuma.jvmarg.com.sun.management.jmxremote.password.file=$HOME/.lookerjmx/jmxremote.password"
ENV JAVAARGS ""
ENV JAVAJVMARGS "-XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:MinRAMPercentage=50 -XX:MaxRAMPercentage=80"
ENV LOOKERARGS "--no-daemonize --log-format=json --no-log-to-file"
ENV LOOKEREXTRAARGS ""
ENV PROTOCOL "https"

USER looker

CMD tini -- java $JAVAJVMARGS $JAVAARGS -jar $LOOKER_DIR/looker.jar start $LOOKERARGS $LOOKEREXTRAARGS
