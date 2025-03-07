# Stage 1: Baixa o K3s da imagem oficial
ARG K3S_TAG="v1.21.2-k3s1"
FROM rancher/k3s:$K3S_TAG AS k3s

# Stage 2: Instalar cni-plugins no Alpine (stage intermediário "dependencies")
FROM alpine:3.18 AS dependencies

RUN apk add --no-cache cni-plugins

# Stage 3: Configura a imagem final baseada em Alpine
FROM alpine:3.18

ENV PATH="$PATH:/usr/local/bin:/opt/cni/bin:/usr/libexec/cni:/bin/aux"
ENV DOCKER_INIT="true"

# Cópia dos arquivos necessários do K3s e dos plugins CNI do stage intermediário
COPY --from=k3s /bin/k3s /bin/k3s
COPY --from=k3s /bin/kubectl /bin/kubectl
COPY --from=k3s /bin/crictl /bin/crictl
COPY --from=k3s /bin/ctr /bin/ctr
COPY --from=k3s /bin/containerd /bin/containerd
COPY --from=dependencies /usr/libexec/cni /usr/libexec/cni

# Criação de diretórios e permissões
RUN mkdir -p /etc/rancher/k3s \
    /var/lib/rancher/k3s \
    /var/lib/kubelet \
    /var/lib/cni \
    /run/k3s \
    /var/log \
    && chmod 1777 /tmp

# Montagem do Cgroup Memory (para contornar o erro de memória)
RUN mkdir -p /sys/fs/cgroup/memory || true

# Expõe volumes para persistência
VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log
VOLUME /sys/fs/cgroup
VOLUME /var/run/docker.sock

# Define o ponto de entrada
ENTRYPOINT ["/bin/k3s", "agent"]