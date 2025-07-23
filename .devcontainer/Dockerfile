FROM mcr.microsoft.com/devcontainers/base:noble

ARG USERNAME=vscode
ARG USER_HOME_PATH="/home/${USERNAME}"

# Validate that this Dockerfile is being built within VS Code devcontainer context
ARG vscodedevcontainer
RUN if [[ -z "$vscodedevcontainer" ]] ; then printf "\nERROR: This Dockerfile needs to be built with VS Code !" && exit 1; else printf "VS Code is detected: $vscodedevcontainer"; fi

# Install system packages required for ansible role testing and aptly package management
# Using DEBIAN_FRONTEND=noninteractive prevents prompts during package installation
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        apt-utils \
        dialog \
        curl \
        gnupg2 \
        rng-tools \
        systemd \
        systemd-sysv \
        python3-dev \
        python3-pip \
        build-essential \
        rsync \
        openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Configure systemd to work properly in containers
# This enables services like rng-tools used by the aptly role
RUN systemctl set-default multi-user.target \
    && systemctl mask systemd-networkd-wait-online.service \
    && systemctl mask systemd-resolved.service \
    && systemctl mask systemd-logind.service

# Configure complete shell environment and persistent history
# Follows VS Code devcontainer best practices for bash history persistence
RUN echo "eval \"\$(register-python-argcomplete pipx)\"" >> ${USER_HOME_PATH}/.bashrc \
    && SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && echo "$SNIPPET" >> "/root/.bashrc" \
    && echo "$SNIPPET" >> "${USER_HOME_PATH}/.bashrc" \
    && mkdir -p /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory

# Set up molecule test directory structure
RUN mkdir -p ${USER_HOME_PATH}/.cache/molecule \
    && chown -R $USERNAME:$USERNAME ${USER_HOME_PATH}/.cache

STOPSIGNAL SIGRTMIN+3

# Initialize systemd
CMD ["/sbin/init"] 
