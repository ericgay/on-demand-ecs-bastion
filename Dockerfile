FROM alpine:latest

RUN apk add --no-cache openssh bash wget curl python py-pip
RUN pip install awscli

RUN sed -i 's/\#PubkeyAuthentication\ yes/PubkeyAuthentication\ yes/' /etc/ssh/sshd_config && \
    sed -i 's/\#PasswordAuthentication\ yes/PasswordAuthentication\ no/' /etc/ssh/sshd_config && \
    sed -i 's/\#X11Forwarding\ no/X11Forwarding\ yes/' /etc/ssh/sshd_config && \
    sed -i 's/\#AllowTcpForwarding\ yes/AllowTcpForwarding\ yes/' /etc/ssh/sshd_config && \
    sed -i 's/\#AllowAgentForwarding\ yes/AllowAgentForwarding\ yes/' /etc/ssh/sshd_config && \
    sed -i 's/\#UseDNS\ no/UseDNS\ no/' /etc/ssh/sshd_config && \
    ssh-keygen -A

RUN adduser -s /bin/bash -D bastion && passwd -d bastion && mkdir -p /home/bastion/.ssh
RUN chown bastion /home/bastion/.ssh && chmod 700 /home/bastion/.ssh

COPY docker-entrypoint.sh /home/bastion/
RUN chmod +x /home/bastion/docker-entrypoint.sh

ENTRYPOINT ["/home/bastion/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]

EXPOSE 22
