# Inspired from https://github.com/geerlingguy/docker-ubuntu1804-ansible/blob/master/Dockerfile
# It's a custom Ubuntu systemd container to be docker-run with the flags '--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro'
#
FROM ubuntu:18.04
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LC_CTYPE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      iproute2 \
      locales \
      lsb-release \
      openssh-server \
      rsyslog \
      software-properties-common \
      sudo \
      systemd \
      systemd-cron \
      wget \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# Fix potential UTF-8 errors with ansible-test.
RUN locale-gen en_US.UTF-8

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
RUN rm -f /lib/systemd/system/systemd*udev* \
  && rm -f /lib/systemd/system/getty.target

## Enable SSH for Vagrant provisionning
RUN systemctl enable ssh

ARG ADMIN_USERNAME=vagrant

RUN useradd --create-home --gid sudo --shell /bin/bash "${ADMIN_USERNAME}" \
  && echo "${ADMIN_USERNAME}:${ADMIN_USERNAME}" | chpasswd \
  && mkdir -p /home/"${ADMIN_USERNAME}"/.ssh \
  && curl -sSL https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -o /home/"${ADMIN_USERNAME}"/.ssh/authorized_keys \
  && chmod 0700 /home/"${ADMIN_USERNAME}"/.ssh \
  && chmod 0600 /home/"${ADMIN_USERNAME}"/.ssh/* \
  && chown -R "${ADMIN_USERNAME}" /home/"${ADMIN_USERNAME}" \
  && echo "${ADMIN_USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"${ADMIN_USERNAME}" \
  && sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Disable daily apt unattended updates.
RUN echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/lib/systemd/systemd"]
