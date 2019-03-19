FROM oryxprod/node-8.1:20190315.3

LABEL maintainer="Azure App Services Container Images <appsvc-images@microsoft.com>"

COPY startup /opt/startup
COPY hostingstart.html /home/site/wwwroot/hostingstart.html

RUN mkdir -p /home/LogFiles \
     && echo "root:Docker!" | chpasswd \
     && echo "cd /home" >> /etc/bash.bashrc \
     && apt update \
     && apt install -y --no-install-recommends openssh-server vim curl wget tcptraceroute

RUN rm -f /etc/ssh/sshd_config
COPY sshd_config /etc/ssh/

# Workaround for https://github.com/npm/npm/issues/16892
# Running npm install as root blows up in a  --userns-remap
# environment.

RUN chmod -R 777 /opt/startup \
     && mkdir /opt/pm2 \
     && chmod 777 /opt/pm2 \
     && ln -s /opt/pm2/node_modules/pm2/bin/pm2 /usr/local/bin/pm2

USER node

RUN cd /opt/pm2 \
  && npm install pm2 \
  && cd /opt/startup \
  && npm install

USER root

# End workaround

ENV PORT 8080
ENV SSH_PORT 2222
EXPOSE 2222 8080

ENV PM2HOME /pm2home

ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/home/site/wwwroot

WORKDIR /home/site/wwwroot

ENTRYPOINT ["/opt/startup/init_container.sh"]
