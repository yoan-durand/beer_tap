ARG FROM_IMAGE=nginx:1.13
FROM ${FROM_IMAGE}

RUN apt-get update && apt-get install -y build-essential curl

ARG ARTIFACTORY_USER
ARG ARTIFACTORY_PASSWORD
ARG ARTIFACT_URI
ARG COMMIT_SHA

RUN \
  COMMIT_SHA=${COMMIT_SHA} \
  mkdir -p /var/www/html && \
  cd /var/www/html && \
  curl -u${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD} ${ARTIFACT_URI} | tar xzv
