FROM docker:dind

# Install base dependencies
RUN echo "Installing base dependencies" && \
    apk add --no-cache bash sudo curl tar libstdc++ libgcc

# Install Node.js 22 directly (Alpine-compatible binary)
RUN echo "Installing Node.js 22 (Alpine binary)" && \
    curl -fsSL https://unofficial-builds.nodejs.org/download/release/v22.13.0/node-v22.13.0-linux-x64-musl.tar.xz -o node.tar.xz && \
    mkdir -p /usr/local/lib/nodejs && \
    tar -xJf node.tar.xz -C /usr/local/lib/nodejs && \
    rm node.tar.xz && \
    ln -s /usr/local/lib/nodejs/node-v22.13.0-linux-x64-musl/bin/node /usr/bin/node && \
    ln -s /usr/local/lib/nodejs/node-v22.13.0-linux-x64-musl/bin/npm /usr/bin/npm && \
    ln -s /usr/local/lib/nodejs/node-v22.13.0-linux-x64-musl/bin/npx /usr/bin/npx

# Verify installation
RUN node -v && npm -v

CMD ["/bin/bash", "-c", "sleep infinity"]
