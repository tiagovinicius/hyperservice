# Define uma imagem base com opção de argumento
ARG BASE_IMAGE=node:23-bookworm-slim
FROM ${BASE_IMAGE} AS base

COPY . /

# Define o comando de entrada
ENTRYPOINT ["hy-dp"]