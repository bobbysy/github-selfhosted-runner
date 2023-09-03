# Tag this as nvcr.io/nvidia/cuda:12.2.0-devel-ubuntu20.04-custom
ARG CUDA_VERSION=12.2.0
ARG UBUNTU_VERSION=20.04
FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

COPY ./scripts /scripts

RUN --mount=type=secret,id=mysecret \
    apt-get update -y \
    && apt-get -y install --no-install-recommends jq curl \
    && cd /scripts \
    && ./github-actions-runner-download.sh \
    && ./docker-in-docker-install.sh \
    && ./python-install.sh \
    && ./git-install.sh \
    && ./node-install.sh \
    && ./terraform-install.sh
