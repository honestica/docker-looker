FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get -y install \
  ca-certificates \
  curl \
  jq \
  phantomjs \
  libc6-dev \
  libfontconfig1 \
  mysql-client \
  tzdata \
  openjdk-11-jre \
  git \
  --no-install-recommends \
  && apt-get upgrade -y

RUN groupadd looker && useradd -m -g looker -s /bin/bash looker

ENV HOME /home/looker
RUN mkdir -p $HOME
WORKDIR $HOME
COPY \
  templates/provision.yaml \
  $HOME/

ARG LICENSE
ARG EMAIL
RUN echo $LICENSE
RUN curl -X POST -H 'Content-Type: application/json' -d '{"lic": "'"$LICENSE"'", "email": "'"$EMAIL"'", "latest": "specific", "specific": "looker-7.18.21.jar"}' https://apidownload.looker.com/download > api_response.json \
  && cat api_response.json && curl "$(cat api_response.json | jq -r '.url')" -o $HOME/looker.jar \
  && curl "$(cat api_response.json | jq -r '.depUrl')" -o $HOME/looker-dependencies.jar

COPY templates/looker_run.sh $HOME/looker_run.sh

RUN chown -R looker:looker $HOME

ENV PORT 9999
EXPOSE 9999

ENV API_PORT 19999
EXPOSE 19999

CMD ["/home/looker/looker_run.sh", "start"]
