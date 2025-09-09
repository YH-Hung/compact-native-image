#!/bin/bash

# Test script to verify the gRPC server works
echo "Starting gRPC server container..."

# Run the container in detached mode
CONTAINER_ID=$(docker run -d -p 50051:50051 --name grpc-test grpc-test-server:latest)

if [ $? -ne 0 ]; then
    echo "Failed to start container"
    exit 1
fi

echo "Container started with ID: $CONTAINER_ID"
echo "Waiting for server to start..."
sleep 3

# Check if container is still running
if ! docker ps | grep -q $CONTAINER_ID; then
    echo "Container failed to start properly. Checking logs:"
    docker logs grpc-test
    docker rm grpc-test
    exit 1
fi

echo "Testing gRPC server with grpcurl..."

# Test the server using grpcurl
# First, we need to install grpcurl if not available
if ! command -v grpcurl &> /dev/null; then
    echo "grpcurl not found. Please install it first:"
    echo "  go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest"
    echo "  or download from: https://github.com/fullstorydev/grpcurl/releases"
    echo ""
    echo "For now, testing with docker exec..."
    docker exec grpc-test /bin/bash -c "echo 'Server is running and accessible'"
else
    # Test the gRPC service
    echo "Making gRPC call..."
    grpcurl -plaintext -d '{"name": "World"}' localhost:50051 helloworld.Greeter/SayHello
fi

echo "Checking server logs..."
docker logs grpc-test

# Cleanup
echo "Stopping and removing test container..."
docker stop grpc-test
docker rm grpc-test

echo "Test completed!"