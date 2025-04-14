FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install all required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-arm-linux-gnueabi \
    g++-arm-linux-gnueabi \
    make \
    bc \
    bison \
    flex \
	libssl-dev \
    libncurses-dev \
	libncurses5-dev \
    wget \
	rsync \
	gawk \
	python3 \
	parted \
	dosfstools \
	udev \
	kpartx \
    curl \
    git \
    xz-utils \
    file \
    ca-certificates \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Set default working directory
WORKDIR /build

