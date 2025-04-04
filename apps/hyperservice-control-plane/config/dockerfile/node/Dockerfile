ARG BASE_IMAGE=node:23-bookworm-slim

ARG K3S_TAG="v1.31.5-k3s1"
FROM rancher/k3s:$K3S_TAG AS k3s


FROM alpine:3.18 AS dependencies

RUN apk add --no-cache ca-certificates cni-plugins bash iptables
RUN update-ca-certificates


FROM ${BASE_IMAGE}

ENV PATH="$PATH:/usr/local/bin:/opt/cni/bin:/usr/libexec/cni:/bin/aux"
ENV DOCKER_INIT="true"
ENV CRI_CONFIG_FILE="/var/lib/rancher/k3s/agent/etc/crictl.yaml"

RUN mkdir -p /etc && \
    echo 'hosts: files dns' > /etc/nsswitch.conf && \
    echo "PRETTY_NAME=\"K3s\"" > /etc/os-release

RUN mkdir -p /tmp/bin
COPY --from=k3s /bin /tmp/bin
RUN cp -n -r /tmp/bin/* /bin/ && rm -rf /tmp/bin

COPY --from=dependencies /etc/ssl/certs /etc/ssl/certs
COPY --from=dependencies /etc/nsswitch.conf /etc/nsswitch.conf

RUN mkdir -p /etc/rancher/k3s \
    /var/lib/rancher/k3s \
    /var/lib/kubelet \
    /var/lib/cni \
    /run/k3s \
    && chmod 1777 /tmp

VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log
VOLUME /var/run/docker.sock

ENTRYPOINT ["/bin/k3s", "agent"]