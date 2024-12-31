FROM dokku/dokku:0.35.12

RUN echo "Installing base dependencies" && \
    apt-get update && \
    apt-get install -y sudo && \
    apt-get install -y coreutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "Setting up Dokku privileges" && \
    echo "%dokku ALL=(ALL:ALL) NOPASSWD:SETENV: /usr/bin/dokku" | \
    sudo tee /etc/sudoers.d/dokku-users

# RUN echo "Seting up SSH" && \
#     mkdir -p ~/.ssh && \
#     ssh-keygen -t ed25519 -f ~/.ssh/ed25519 -N "" && \
#     chown -R dokku:dokku ~/.ssh && \
#     cat ~/.ssh/ed25519.pub >> ~/.ssh/authorized_keys && \
#     echo -e "Host dokku.docker\n  HostName 127.0.0.1\n  Port 3022" >> ~/.ssh/config

# RUN echo "Setting up Postgres Plugin" && \
#     dokku plugin:install \
#     https://github.com/dokku/dokku-postgres.git postgres
# RUN echo "Setting up Redis Plugin" && \
#     dokku plugin:install \
#     https://github.com/dokku/dokku-redis.git redis