FROM debian:bookworm-slim

LABEL maintainer=$USERNAME
LABEL org.opencontainers.image.source="https://github.com/acherry-io/dev-container-base"

USER root

# Install openssh, shell, and other core dev tools for user
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends && \
    apt-get install -y openssh-server && \
    apt-get install -y zsh && \
    apt-get install -y build-essential && \
    apt-get install -y curl


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


# If this directory doesn't exist, sshd will not work
RUN mkdir -p /var/run/sshd

# Configure sshd
COPY ./sshd_config /etc/ssh/sshd_config

# Generate all missing default SSH host keys for fresh install
RUN ssh-keygen -A

EXPOSE 22

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 544 /entrypoint.sh


ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

# Install core dev and nvim dependencies
# Prep nodejs instsll
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sh

RUN apt-get install -y fd-find
RUN apt-get install -y git
RUN apt-get install -y luarocks
RUN apt-get install -y libreadline-dev
RUN apt-get install -y nodejs
RUN apt-get install -y ripgrep
RUN apt-get install -y unzip

RUN apt-get clean

# Update npm just in case!
RUN npm install -g npm

RUN npm install -g tree-sitter-cli
RUN npm install -g neovim

