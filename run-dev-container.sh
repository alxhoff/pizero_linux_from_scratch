#!/bin/bash
set -e

TAG=pizero-cross:latest
CONTAINER_NAME=pizero-cross-dev

# Build image if it doesn't exist
if ! docker image inspect $TAG >/dev/null 2>&1; then
    echo "🔨 Building the container image..."
    docker build -t $TAG -f Dockerfile .
fi

# Run or reattach to the persistent container
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "🔁 Starting existing container..."
    docker start -ai $CONTAINER_NAME
else
    echo "🚀 Running new persistent container..."
    docker run --privileged -it --name $CONTAINER_NAME \
        -v "$(pwd)":/build \
        -w /build \
        $TAG \
        bash
fi

