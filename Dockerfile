# Base Image
FROM ubuntu:23.10

# Metadata
LABEL maintainer="Shane Holloman"

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://localhost/ || exit 1

# Environment Variables
ARG DEBIAN_FRONTEND=noninteractive
ENV pip_packages "ansible"

# Update package lists
RUN apt-get update

# Upgrade all packages
RUN apt-get dist-upgrade -y --no-install-recommends

# Install base packages
RUN apt-get install -y apt-utils build-essential locales

# Install libraries
RUN apt-get install -y libffi-dev libssl-dev libyaml-dev

# Install Python
RUN apt-get install -y python3-dev python3-pip python3-yaml python3-setuptools

# Install other utilities
RUN apt-get install -y software-properties-common rsyslog systemd systemd-cron sudo iproute2

# Cleanup
RUN apt-get clean \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man

RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# Fix potential UTF-8 errors with ansible-test.
RUN locale-gen en_US.UTF-8

# Install Ansible via Pip.
RUN pip3 install $pip_packages --break-system-packages

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
RUN rm -f /lib/systemd/system/systemd*udev* \
    && rm -f /lib/systemd/system/getty.target

# Volumes and Command
VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/lib/systemd/systemd"]
