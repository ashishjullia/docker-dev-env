FROM ubuntu:20.04

ENV NVM_DIR /usr/local/nvm

# Install all dependencies, NVM, GitHub CLI, and other tools in a single RUN command
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
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh \
    && git clone https://github.com/tfutils/tfenv.git ~/.tfenv \
    && pip3 install urllib3==1.26.7 print-env \
    && mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    # Install GitHub CLI
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /awscliv2.zip

# Set environment path for tfenv and NVM
ENV PATH="/root/.tfenv/bin:$NVM_DIR/versions/node/$(nvm version)/bin:$PATH"

# Create and set the working directory
WORKDIR /work

# Copy the script into the container
COPY ./script.sh /
RUN chmod u+x /script.sh
