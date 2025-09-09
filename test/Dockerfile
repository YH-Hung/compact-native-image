# Use our gRPC base image
FROM grpc-base:latest AS builder

# Switch to root to install build dependencies
USER root

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy source files
COPY . /app/src
WORKDIR /app/src

# Build the application
RUN mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc)

# Final runtime stage
FROM grpc-base:latest

# Switch to root temporarily to copy files
USER root

# Copy the built binary
COPY --from=builder /app/src/build/greeter_server /app/greeter_server

# Make sure the binary is executable and owned by grpcuser
RUN chmod +x /app/greeter_server && \
    chown grpcuser:grpcuser /app/greeter_server

# Switch back to non-root user
USER grpcuser

# Expose the gRPC port
EXPOSE 50051

# Run the server
CMD ["/app/greeter_server"]