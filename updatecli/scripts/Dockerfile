FROM ubuntu:bionic

LABEL version="0.1"
LABEL maintaner="Antoine Neveux <aneveux@cloudbees.com>"
LABEL description="Ubuntu based image with docker-ce repository installed in order to check for latest available version"

# Installing docker-ce requirements
RUN apt-get update -q && apt-get install -qy ca-certificates curl gnupg lsb-release
# Installing docker-ce gpg key
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# Installing docker-ce apt repository
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
# Updating apt indexes
RUN apt-get update -q

# Adding our docker-ce version script
COPY docker-ce-updates.sh /app/docker-ce-updates.sh
# Making the script executable
RUN chmod +x /app/docker-ce-updates.sh

# Executing the script when running the image
ENTRYPOINT [ "/app/docker-ce-updates.sh" ]
