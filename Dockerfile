# Changed base to Ubuntu 24.04
FROM ubuntu:25.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TERRAFORM_VERSION
ARG TARGETOS
ARG TARGETARCH
ARG INSTALL_AZURE_CLI
ARG INSTALL_AWS_CLI

# Base tools + sudo
RUN apt-get update && apt-get install --yes --no-install-recommends \
      curl unzip git wget bash less software-properties-common lsb-release bash-completion sudo \
      iputils-ping dnsutils traceroute less groff man-db \
  && rm -rf /var/lib/apt/lists/*

# Terraform (linux_amd64 or linux_arm64)
RUN curl -Lo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TARGETOS}_${TARGETARCH}.zip" \
 && unzip /tmp/terraform.zip -d /usr/local/bin \
 && rm /tmp/terraform.zip

# Install Terraform Lint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
# Install TfSec
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Azure CLI (conditional)
RUN if [ "${INSTALL_AZURE_CLI}" = "YES" ]; then \
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; \
  fi

# AWS CLI (conditional)
RUN if [ "${INSTALL_AWS_CLI}" = "YES" ]; then \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws; \
  fi

# Create user and grant passwordless sudo
RUN adduser --disabled-password --gecos "" tfuser \
 && usermod --append --groups sudo tfuser \
 && echo 'tfuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-tfuser \
 && chmod 0440 /etc/sudoers.d/90-tfuser

## Customization to show the current terraform workspace
USER tfuser
RUN echo 'if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi' >> /home/tfuser/.bashrc \
 && echo '' >> /home/tfuser/.bashrc \
 && echo '# Function to get current Terraform workspace' >> /home/tfuser/.bashrc \
 && echo 'tf_workspace() {' >> /home/tfuser/.bashrc \
 && echo '  if [ -d .terraform ]; then' >> /home/tfuser/.bashrc \
 && echo '    local ws=$(terraform workspace show 2>/dev/null)' >> /home/tfuser/.bashrc \
 && echo '    if [ -n "$ws" ]; then' >> /home/tfuser/.bashrc \
 && echo '      echo " ($ws)"' >> /home/tfuser/.bashrc \
 && echo '    fi' >> /home/tfuser/.bashrc \
 && echo '  fi' >> /home/tfuser/.bashrc \
 && echo '}' >> /home/tfuser/.bashrc \
 && echo '' >> /home/tfuser/.bashrc \
 && echo 'alias tf="terraform" ' >> /home/tfuser/.bashrc \
 && echo '# Custom prompt with Terraform workspace' >> /home/tfuser/.bashrc \
 && echo 'PS1="\[\e[32m\]\u@\h\[\e[0m\] : \[\e[34m\]\w\[\e[0m\] :\[\e[33m\]\$(tf_workspace)\[\e[0m\] \\$ "' >> /home/tfuser/.bashrc

CMD ["tail", "-f", "/dev/null"]