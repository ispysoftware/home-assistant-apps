# Thin wrapper around the official image. The Supervisor builds this on the
# device and passes BUILD_VERSION (the app's version from config.yaml); the
# default is only a fallback and is bumped together with config.yaml.
ARG BUILD_VERSION=8.2.3.0
FROM ispysoftware/agentdvr:${BUILD_VERSION}

# TEST BRANCH ONLY (ingress-test): lay a local Linux64 build over the image,
# the same way the image itself installs the release zip. Served from the dev
# PC's LAN address by serve-ha-test-build.ps1 (-ServeIP; the test VM is bridged
# onto the LAN). If the PC's address changes, update both.
ARG TEST_BUILD_URL=http://192.168.0.162:8765/agent.tar.gz
ADD ${TEST_BUILD_URL} /tmp/agent.tar.gz
RUN tar -xzf /tmp/agent.tar.gz -C /AgentDVR \
 && rm -f /tmp/agent.tar.gz \
 && chmod +x /AgentDVR/Agent \
 && find /AgentDVR -name '*.sh' -exec chmod +x {} + \
 && cd /AgentDVR && rm -f setup.sh agent-register.sh agent-reset.sh agent-reset-account.sh \
    agent-reset-local-login.sh setup-ffmpeg-osx.sh agent-uninstall-service.sh agent-update.sh

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
