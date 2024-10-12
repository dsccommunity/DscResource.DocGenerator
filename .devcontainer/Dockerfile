# Use the official PowerShell image as the base
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

# Add a label to name your image
LABEL name="dscresource-docgenerator"

# Set environment variables for versions
# Debian version should be the same as the base image.
ENV UBUNTU_VERSION=22.04
ENV DOTNET_SDK_VERSION=8.0
ENV POWERSHELL_VERSION=7.4.5
ENV POWERSHELL_PACKAGE_REVISION=1

# Install necessary packages
# hadolint ignore=DL3008
RUN wget https://packages.microsoft.com/config/ubuntu/$UBUNTU_VERSION/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    sudo dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    dotnet-sdk-$DOTNET_SDK_VERSION \
    git \
    wget \
    curl \
    unzip \
    sudo \
    nano \
    locales \
    apt-transport-https \
    ca-certificates \
    gpg \
    gnupg2 \
    software-properties-common && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Update PowerShell to the specified version
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell_${POWERSHELL_VERSION}-${POWERSHELL_PACKAGE_REVISION}.deb_amd64.deb -O powershell.deb \
    && dpkg -i powershell.deb \
    && apt-get update \
    && apt-get install -f \
    && rm powershell.deb \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Set the default shell to PowerShell
ENV SHELL pwsh

# Set up a user (optional)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Explanation:
# 1. groupadd: Creates a new group with the specified GID ($USER_GID)
# 2. useradd: Creates a new user with the specified UID ($USER_UID) and GID ($USER_GID)
#    The -m flag creates a home directory for the user
# 3. echo: Adds a sudoers entry for the new user, allowing them to use sudo without a password
# 4. chmod: Sets the permissions of the sudoers file to be read-only (0440)
#
# This setup creates a non-root user with sudo privileges, which is a common
# practice in Docker containers for better security and to avoid running
# processes as root.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to non-root user
USER $USERNAME

# Set the working directory
WORKDIR /workspace

# Install GitVersion as a dotnet tool for the vscode user
RUN dotnet tool install --global GitVersion.Tool

# Add alias for gitversion, ensuring a newline before the alias
RUN printf "\nalias gitversion=\"dotnet-gitversion\"\n" >> /home/$USERNAME/.bashrc
