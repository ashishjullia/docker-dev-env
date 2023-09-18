FROM amazon/aws-cli
RUN yum -y update && yum -y updateinfo && yum install -y \
    git \
    jq \
    unzip \
    curl \
    wget \
    tar \
    openssl \
    which \
    python3 \
    python3-pip \
    && git clone https://github.com/tfutils/tfenv.git ~/.tfenv \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && sh ./get_helm.sh \
    && yum upgrade openssl \
    && pip3 install urllib3==1.26.7 \
    && pip3 install print-env \
    && yum clean all
ENV PATH="/root/.tfenv/bin:$PATH"
RUN mkdir /work
WORKDIR /work
COPY ./script.sh /
RUN chmod u+x /script.sh
