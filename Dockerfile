FROM alpine:latest

RUN apk --no-cache add bash coreutils curl jq

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.name="pagerduty-event-resource" \
      org.label-schema.description="A Concourse resource for triggering PagerDuty incidents." \
      org.label-schema.vcs-url="https://github.com/coralogix/eng-concourse-resource-pagerduty-incident" \
      org.label-schema.vendor="Coralogix, Inc." \
      org.label-schema.version="v0.1.0"

WORKDIR /opt/resource

COPY src/check /opt/resource/check
COPY src/in    /opt/resource/in
COPY src/out   /opt/resource/out
