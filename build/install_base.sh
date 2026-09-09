#!/usr/bin/env bash
set -euo pipefail

# Remove docker-clean config that would override Keep-Downloaded-Packages
rm -f /etc/apt/apt.conf.d/docker-clean
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Remove lock files from cache mounts (Docker best practice)
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/apt/lists/lock

function apt_install_with_software_properties_common_fallback() {
  local -a packages=("$@")
  local -a fallback_packages=()
  local package
  local has_software_properties_common=false

  for package in "${packages[@]}"; do
    if [[ "${package}" == "software-properties-common" ]]; then
      has_software_properties_common=true
    else
      fallback_packages+=("${package}")
    fi
  done

  if [[ "${has_software_properties_common}" == "true" ]]; then
    apt-get install -y --no-install-recommends "${packages[@]}" \
      || apt-get install -y --no-install-recommends "${fallback_packages[@]}"
  else
    apt-get install -y --no-install-recommends "${packages[@]}"
  fi
}

# Required by the build or runner operation
function install_essentials() {
  apt_install_with_software_properties_common_fallback \
      libicu-dev \
      lsb-release \
      ca-certificates \
      curl \
      git \
      jq \
      gnupg \
      software-properties-common \
      tar \
      unzip \
      zip \
      apt-transport-https \
      sudo \
      gcc \
      dirmngr \
      locales \
      gosu \
      gpg-agent \
      dumb-init \
      redis-server \
      httpie \
      libsqlite3-dev \
      python3
}

function install_tools_apt() {
  local apt_packages_list
  local -a packages=()

  apt_packages_list="$(apt_packages)"
  if [[ -n "${apt_packages_list}" ]]; then
    read -r -a packages <<< "${apt_packages_list}"
    apt_install_with_software_properties_common_fallback "${packages[@]}"
  fi
}

function remove_caches() {
  # Don't clean apt caches - they're persisted by BuildKit cache mounts
  # This follows Docker's recommended pattern for cache mounts:
  # https://docs.docker.com/reference/dockerfile/#example-cache-apt-packages
  
  # Clean temp directories to reduce final image size
  rm -rf /tmp/*
  rm -rf /var/tmp/*
}

function setup_sudoers() {
  sed -e 's/Defaults.*env_reset/Defaults env_keep = "HTTP_PROXY HTTPS_PROXY NO_PROXY FTP_PROXY http_proxy https_proxy no_proxy ftp_proxy"/' -i /etc/sudoers
  echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
}

echo en_US.UTF-8 UTF-8 >> /etc/locale.gen

scripts_dir=$(dirname "$0")
# shellcheck source=/dev/null
source "$scripts_dir/sources.sh"
# shellcheck source=/dev/null
source "$scripts_dir/tools.sh"
# shellcheck source=/dev/null
source "$scripts_dir/config.sh"

# Do a much-needed upgrade first
apt-get update
apt-get upgrade -y

# Then do some installing
install_essentials
configure_sources

apt-get update
install_tools_apt
install_tools

# setup_sudoers
# groupadd -g "$(group_id)" runner
# useradd -mr -d /home/runner -u "$(user_id)" -g "$(group_id)" runner
# usermod -aG sudo runner
# usermod -aG docker runner

remove_sources
remove_caches
