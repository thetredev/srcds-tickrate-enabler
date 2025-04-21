FROM mcr.microsoft.com/vscode/devcontainers/cpp:bookworm

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y update \
  && apt-get -y install \
    git \
    build-essential \
    gcc-multilib \
    g++-multilib \
    lib32stdc++6 \
    python3-venv \
    python3-pip \
    python3-wheel \
    libelf-dev \
  && apt-get -y autoremove \
  && apt-get -y autoclean \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/*

RUN git config --system user.name 'github-actions' \
  && git config --system user.email 'actions@github.com' \
  && git config --system --add safe.directory '*'

USER vscode
