#!/usr/bin/env bash
set -euo pipefail

function install_git() {
  ( apt-get install -y --no-install-recommends git \
   || apt-get install -t stable -y --no-install-recommends git )
}

function install_liblttng-ust() {
  if [[ $(apt-cache search -n liblttng-ust0 | awk '{print $1}') == "liblttng-ust0" ]]; then
    apt-get install -y --no-install-recommends liblttng-ust0
  fi

  if [[ $(apt-cache search -n liblttng-ust1 | awk '{print $1}') == "liblttng-ust1" ]]; then
    apt-get install -y --no-install-recommends liblttng-ust1
  fi
}

function install_aws-cli() {
  ( curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" \
    && unzip -q awscliv2.zip -d /tmp/ \
    && /tmp/aws/install \
    && rm awscliv2.zip \
  ) \
    || pip3 install --no-cache-dir awscli
}

function install_azure-cli() {
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
}

function install_git-lfs() {
  local DPKG_ARCH
  DPKG_ARCH="$(dpkg --print-architecture)"

  curl -s "https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-${DPKG_ARCH}-v${GIT_LFS_VERSION}.tar.gz" -L -o /tmp/lfs.tar.gz
  tar -xzf /tmp/lfs.tar.gz -C /tmp
  "/tmp/git-lfs-${GIT_LFS_VERSION}/install.sh"
  rm -rf /tmp/lfs.tar.gz "/tmp/git-lfs-${GIT_LFS_VERSION}"
}

function install_docker-cli() {
  apt-get install -y docker-ce-cli --no-install-recommends --allow-unauthenticated
}

function install_docker() {
  apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin containerd.io docker-compose-plugin --no-install-recommends --allow-unauthenticated

  echo -e '#!/bin/sh\ndocker compose --compatibility "$@"' > /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  sed -i 's/ulimit -Hn/# ulimit -Hn/g' /etc/init.d/docker
}

function install_container-tools() {
  ( apt-get install -y --no-install-recommends podman buildah skopeo || : )
}

function install_github-cli() {
  local DPKG_ARCH GH_CLI_VERSION GH_CLI_DOWNLOAD_URL

  DPKG_ARCH="$(dpkg --print-architecture)"

  GH_CLI_VERSION=$(curl -sL -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/cli/cli/releases/latest \
      | jq -r '.tag_name' | sed 's/^v//g')

  GH_CLI_DOWNLOAD_URL=$(curl -sL -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/cli/cli/releases/latest \
      | jq ".assets[] | select(.name == \"gh_${GH_CLI_VERSION}_linux_${DPKG_ARCH}.deb\")" \
      | jq -r '.browser_download_url')

  curl -sSLo /tmp/ghcli.deb "${GH_CLI_DOWNLOAD_URL}"
  apt-get -y install /tmp/ghcli.deb
  rm /tmp/ghcli.deb
}

function install_yq() {
  local DPKG_ARCH YQ_DOWNLOAD_URL

  DPKG_ARCH="$(dpkg --print-architecture)"

  YQ_DOWNLOAD_URL=$(curl -sL -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/mikefarah/yq/releases/latest \
      | jq ".assets[] | select(.name == \"yq_linux_${DPKG_ARCH}.tar.gz\")" \
      | jq -r '.browser_download_url')

  curl -s "${YQ_DOWNLOAD_URL}" -L -o /tmp/yq.tar.gz
  tar -xzf /tmp/yq.tar.gz -C /tmp
  mv "/tmp/yq_linux_${DPKG_ARCH}" /usr/local/bin/yq
}

function install_playwright() {
  echo Installing playwright...
  mkdir -p /opt/playwright
  export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
  npm install -g playwright
  # Pre-install browsers and OS dependencies so workflows do not need runtime install steps.
  npx playwright install --with-deps chrome-for-testing chromium-headless-shell firefox webkit ffmpeg chrome msedge
  npm uninstall -g playwright
  npm cache clean --force
  # Remove Node.js after Playwright deps installed - workflows use actions/setup-node
  apt-get remove -y nodejs
  apt-get autoremove -y
}

function install_powershell() {
  local DPKG_ARCH PWSH_VERSION PWSH_DOWNLOAD_URL

  DPKG_ARCH="$(dpkg --print-architecture)"

  PWSH_VERSION=$(curl -sL -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/PowerShell/PowerShell/releases/latest \
      | jq -r '.tag_name' \
      | sed 's/^v//g')

  PWSH_DOWNLOAD_URL=$(curl -sL -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/PowerShell/PowerShell/releases/latest \
      | jq -r ".assets[] | select(.name == \"powershell-${PWSH_VERSION}-linux-${DPKG_ARCH//amd64/x64}.tar.gz\") | .browser_download_url")

  curl -L -o /tmp/powershell.tar.gz "$PWSH_DOWNLOAD_URL"
  mkdir -p /opt/powershell
  tar zxf /tmp/powershell.tar.gz -C /opt/powershell
  chmod +x /opt/powershell/pwsh
  ln -s /opt/powershell/pwsh /usr/bin/pwsh
}

function install_oracle-instant-client() {
  local DPKG_ARCH ORACLE_CLIENT_ARCH LIBAIO_DIR

  DPKG_ARCH="$(dpkg --print-architecture)"

  case "${DPKG_ARCH}" in
    amd64)
      ORACLE_CLIENT_ARCH="x64"
      LIBAIO_DIR="/usr/lib/x86_64-linux-gnu"
      ;;
    arm64)
      ORACLE_CLIENT_ARCH="arm64"
      LIBAIO_DIR="/usr/lib/aarch64-linux-gnu"
      ;;
    *)
      echo "Unsupported architecture for Oracle Instant Client: ${DPKG_ARCH}"
      exit 1
      ;;
  esac

  if apt-cache show libaio1t64 > /dev/null 2>&1; then
    apt-get install -y --no-install-recommends libaio1t64
  else
    apt-get install -y --no-install-recommends libaio1
  fi

  apt-get install -y --no-install-recommends \
    unzip \
    ca-certificates \
    curl

  if [[ -f "${LIBAIO_DIR}/libaio.so.1t64" ]]; then
    ln -sf "${LIBAIO_DIR}/libaio.so.1t64" "${LIBAIO_DIR}/libaio.so.1"
  fi

  mkdir -p /opt/oracle
  curl -L -o /opt/oracle/instantclient.zip \
    "https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_CLIENT_BUILD}/instantclient-basic-linux.${ORACLE_CLIENT_ARCH}-${ORACLE_CLIENT_VERSION}.zip"
  unzip /opt/oracle/instantclient.zip -d /opt/oracle
  rm /opt/oracle/instantclient.zip
  ln -sfn /opt/oracle/instantclient_* /opt/oracle/instantclient

  echo '/opt/oracle/instantclient' > /etc/ld.so.conf.d/oracle-instantclient.conf
  ldconfig

  cat >/etc/profile.d/oracle-instantclient.sh <<'EOF'
export LD_LIBRARY_PATH=/opt/oracle/instantclient${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export PATH=/opt/oracle/instantclient:${PATH}
EOF
}

function install_tools() {
  local function_name
  # shellcheck source=/dev/null
  source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

  script_packages | while read -r package; do
    function_name="install_${package}"
    if declare -f "${function_name}" > /dev/null; then
      "${function_name}"
    else
      echo "No install script found for package: ${package}"
      exit 1
    fi
  done
}

function install_architecture-tools() {
  ( apt-get install -y --no-install-recommends graphviz libgraphviz-dev || : )
}
