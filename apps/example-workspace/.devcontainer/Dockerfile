FROM node:23-bookworm-slim

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    curl nano lsof openssh-client collectd git

# Install hyperservice Control Plane
RUN curl -sL https://raw.githubusercontent.com/tiagovinicius/hyperservice/main/get-hy-cp.sh | bash

# Install hyperservice CLI
RUN curl -sL https://raw.githubusercontent.com/tiagovinicius/hyperservice/main/get-hyctl.sh | bash && \
chmod +x hyctl && mv hyctl /usr/local/bin/

# Install K3d
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Kuma
RUN curl -L https://kuma.io/installer.sh | VERSION=2.9.3 sh - && \
    mv kuma-2.9.3/bin/* /usr/local/bin/ && \
    rm -rf kuma-2.9.3

# Install Moonrepo CLI
RUN curl -fsSL https://moonrepo.dev/install/moon.sh | bash && \
    mv "$HOME/.moon/bin/moon" /usr/local/bin/

ENTRYPOINT ["bash", "true"]
 