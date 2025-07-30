FROM ubuntu:24.04

ARG USER

USER root

RUN apt-get update -y
RUN apt-get install -y software-properties-common
RUN apt-get update -y
RUN apt-get upgrade -y

RUN apt-get install -y --no-install-recommends

# Install ssh server
RUN apt-get install -y openssh-server

# Install shell for user
RUN apt-get install -y zsh

# Install core tools
RUN apt-get install -y curl
RUN apt-get install -y git

# Install nvim tools
RUN apt-get install -y ripgrep
RUN apt-get install -y tree-sitter

RUN apt-get clean

# Get latest version tag and download URL
RUN echo "Getting neovim" && \
  api_url="https://api.github.com/repos/neovim/neovim/releases/latest" && \
  echo "Fetching latest Neovim release info..." && \
  response=$(curl -s $api_url) && \
  latest_tag=$(echo $response | grep -oP '"tag_name":\s*"v\K[^"]+') && \
  echo "Latest version: $latest_tag" && \
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz && \
  tar xzf nvim-linux-arm64.tar.gz && \
  mkdir -p /opt/nvim/$latest_tag && \
  cp -r /nvim-linux-arm64/. /opt/nvim/$latest_tag && \
  rm nvim-linux-arm64.tar.gz && \
  rm -rf nvim-linux-arm64 && \
  ln -s /opt/nvim/$latest_tag/bin/nvim /usr/bin/nvim


# Add user for ssh access
RUN groupadd -g 9999 $USER
RUN useradd -m -s /bin/zsh -u 9999 -g 9999 $USER
RUN echo "$USER:$(head -c 40 /dev/urandom | base64)" | chpasswd


# If this directory doesn't exist, sshd will not work
RUN mkdir -p /var/run/sshd

# Configure sshd
COPY sshd_config /etc/ssh/sshd_config

# Generate all missing default SSH host keys for fresh install
ssh-keygen -A

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
