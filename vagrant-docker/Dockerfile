FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2016
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  apt-utils \
  build-essential \
  curl \
  iproute2 \
  iptables \
  locales \
  lvm2 \
  openssh-server \
  passwd \
  rsyslog \
  software-properties-common \
  sudo \
  systemd \
  systemd-cron \
  wget \
  && apt-get clean \
  && rm -Rf /var/lib/apt/lists/* /usr/share/doc && rm -Rf /usr/share/man \
  && sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf \
  && locale-gen en_US.UTF-8 \
  ## Tuning to allow systemd to work in the container by removing unwanted links and files from the systemd startup hierarchy
  && for file in /lib/systemd/system/sysinit.target.wants/*; do test "$file" == "systemd-tmpfiles-setup.service" || rm -f "$file"; done \
  && rm -f /lib/systemd/system/multi-user.target.wants/* \
  /etc/systemd/system/*.wants/* \
  /lib/systemd/system/local-fs.target.wants/* \
  /lib/systemd/system/sockets.target.wants/*udev* \
  /lib/systemd/system/sockets.target.wants/*initctl* \
  /lib/systemd/system/basic.target.wants/* \
  /lib/systemd/system/anaconda.target.wants/* \
  /run/nologin \
  && systemctl enable ssh.service

## Create the default vagrant user with the default vagrant ssh key - https://www.vagrantup.com/docs/boxes/base#defaultusersettings
RUN useradd --create-home -s /bin/bash vagrant \
  && echo -e "vagrant\nvagrant" | passwd vagrant \
  && echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant \
  && chmod 440 /etc/sudoers.d/vagrant \
  && mkdir -p /home/vagrant/.ssh \
  && chmod 700 /home/vagrant/.ssh \
  # Avoids SSH errors with vagrant: disable requiretty, PAM and DNS
  && sed -i -e 's/Defaults.*requiretty/#&/' /etc/sudoers \
  && sed -i -e 's/\(UsePAM \)yes/\1 no/' /etc/ssh/sshd_config \
  && sed -i -e 's/\(UseDNS \)yes/\1 no/' /etc/ssh/sshd_config

# Define the vagrant insecure key as default for vagrant user
ADD https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub /home/vagrant/.ssh/authorized_keys
RUN chmod 600 /home/vagrant/.ssh/authorized_keys \
  && chown -R vagrant:vagrant /home/vagrant/.ssh

# Install the puppet agent
# hadolint ignore=DL3008,DL3059
RUN package_path=/tmp/puppetrelease.deb \
  && curl --silent --show-error --location --output "${package_path}" "http://apt.puppetlabs.com/puppet6-release-$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2).deb" \
  && dpkg -i "${package_path}" \
  && rm -f /tmp/puppetrelease.deb \
  && apt-get update --quiet \
  && apt-get install --no-install-recommends --yes --quiet puppet \
  && apt-get clean \
  && rm -Rf /var/lib/apt/lists/*

# /sys/fs/cgroup must be a volume to ensure cgroup hierarchy is not on the overlayfs (and should be mounted by user from the host cgroup)
# /tmp and /run are temp. filesystem so at least a data volume outside the container
# /var/lib/docker must be outside the overlay root filesystem
VOLUME ["/sys/fs/cgroup", "/tmp", "/run", "/var/lib/docker"]

# PID 1 must be systemd to ensure we can enable and start services, without dbus error.
# Require privileged mode!
CMD ["/lib/systemd/systemd"]
