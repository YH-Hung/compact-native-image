#!/bin/bash

# Build the base gRPC image
echo "Building gRPC base image..."
docker build -t grpc-base:latest .

if [ $? -ne 0 ]; then
    echo "Failed to build base image"
    exit 1
fi

echo "Base image built successfully!"
echo "Image size:"
docker images grpc-base:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Build the test server image
echo "Building test server image..."
cd test
docker build -t grpc-test-server:latest .

if [ $? -ne 0 ]; then
    echo "Failed to build test server image"
    exit 1
fi

echo "Test server image built successfully!"
echo "Image size:"
docker images grpc-test-server:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

echo "Build completed successfully!"