FROM ubuntu:20.04

ENV NVM_DIR=/usr/local/nvm

# Install dependencies, AWS CLI, kubectl, Helm, tfenv, NVM, and GitHub CLI.
# Node itself is installed at runtime by script.sh when NODE_VERSION is set.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        jq \
        unzip \
        curl \
        wget \
        tar \
        openssl \
        python3 \
        python3-pip \
    && arch=$(dpkg --print-architecture) \
    && case "$arch" in \
        amd64) aws_cli_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; kubectl_arch="amd64" ;; \
        arm64) aws_cli_url="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; kubectl_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "$aws_cli_url" -o awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && curl -fsSL -o kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${kubectl_arch}/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh \
    && git clone https://github.com/tfutils/tfenv.git /root/.tfenv \
    && pip3 install urllib3==1.26.7 print-env \
    && mkdir -p "$NVM_DIR" \
    && curl -fsSL -o /tmp/nvm-install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh \
    && bash /tmp/nvm-install.sh \
    && rm /tmp/nvm-install.sh \
    && curl -fsSL -o /usr/share/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* awscliv2.zip aws kubectl get_helm.sh

# tfenv is a real binary path. nvm is a shell function loaded by script.sh,
# so a node version directory cannot be added here.
ENV PATH="/root/.tfenv/bin:$PATH"

WORKDIR /work

COPY ./script.sh /
COPY ./mfa.sh /usr/local/bin/mfa.sh
COPY ./aws-role-credentials /usr/local/bin/aws-role-credentials
COPY ./aws-mfa-session /usr/local/bin/aws-mfa-session
RUN chmod u+x /script.sh /usr/local/bin/mfa.sh /usr/local/bin/aws-role-credentials /usr/local/bin/aws-mfa-session \
    && printf '\nmfa() { source /usr/local/bin/mfa.sh "$@"; }\n' >> /root/.bashrc
