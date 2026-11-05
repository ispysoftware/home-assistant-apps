# Thin wrapper around the official image. The Supervisor builds this on the
# device and passes BUILD_VERSION (the app's version from config.yaml); the
# default is only a fallback and is bumped together with config.yaml.
ARG BUILD_VERSION=8.2.4.0
FROM ispysoftware/agentdvr:${BUILD_VERSION}


COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
