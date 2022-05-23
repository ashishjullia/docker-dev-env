FROM amazon/aws-cli
RUN yum install git -y && yum install unzip -y && yum install curl -y && yum install wget -y && yum install tar -y && yum install openssl -y
RUN git clone https://github.com/tfutils/tfenv.git ~/.tfenv
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 700 get_helm.sh && sh ./get_helm.sh
ENV PATH="/root/.tfenv/bin:$PATH"
RUN mkdir /work
COPY ./new.sh /work
WORKDIR /work
RUN chmod +x /work/new.sh
ENTRYPOINT ["sh", "/work/new.sh"]