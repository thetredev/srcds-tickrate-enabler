FROM mcr.microsoft.com/vscode/devcontainers/cpp:bookworm

RUN <<EOF
set -xe

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

apt-get update
apt-get -y install \
    git \
    build-essential \
    gcc-multilib \
    g++-multilib \
    bear \
    lib32stdc++6 \
    python3-venv \
    python3-pip \
    python3-wheel \
    libelf-dev \
    git-credential-oauth

apt-get -y autoremove
apt-get -y autoclean
apt-get -y clean
rm -rf /var/lib/apt/lists/*

git config --system user.name 'github-actions'
git config --system user.email 'actions@github.com'
git config --system --add safe.directory '*'
EOF

USER vscode
WORKDIR /home/vscode

RUN echo 'alias make="bear -- make"' >> ~/.bashrc

#RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
