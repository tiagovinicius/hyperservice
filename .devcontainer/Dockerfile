FROM golang:1.24.0-bookworm

RUN echo "Install base dependencies" && \
    apt-get update && apt-get install -y \
    curl nano lsof openssh-client collectd unzip

#---- Dependencies for building example-workspace ----
# Install bun
RUN curl -fsSL https://bun.sh/install | bash

# Install Node
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y nodejs;

#---- Dependencies for building hyperservice ----
# Install Air
RUN go install github.com/air-verse/air@latest


#---- Dependencies for running hyperservice ----
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
 