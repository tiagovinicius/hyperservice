#!/bin/bash

if [ -n "$PUBLIC_KEY" ]; then
  echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chown root:root /root/.ssh/authorized_keys

  # Configurar a chave pública também para o usuário não-root
  mkdir -p /home/user/.ssh
  echo "$PUBLIC_KEY" > /home/user/.ssh/authorized_keys
  chmod 600 /home/user/.ssh/authorized_keys
  chown -R user:user /home/user/.ssh
fi

exec /usr/sbin/sshd -D
