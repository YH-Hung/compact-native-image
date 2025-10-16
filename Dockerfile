# Multi-stage build for minimal image size
FROM ubuntu:22.04 AS builder

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    libtool \
    pkg-config \
    cmake \
    git \
    curl \
    libcurl4-openssl-dev \
    zlib1g-dev \
    ca-certificates \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy grpc, prometheus-cpp, and cpr source code
COPY ../grpc /tmp/grpc
COPY ../prometheus-cpp /tmp/prometheus-cpp
COPY ../cpr /tmp/cpr

# Build and install gRPC, protobuf from source with optimizations
WORKDIR /tmp/grpc
RUN rm -rf cmake/build && mkdir -p cmake/build && cd cmake/build && \
    cmake -DgRPC_INSTALL=ON \
          -DgRPC_BUILD_TESTS=OFF \
          -DgRPC_BUILD_CSHARP_EXT=OFF \
          -DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          ../.. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build and install prometheus-cpp from source with optimizations
WORKDIR /tmp/prometheus-cpp
RUN rm -rf build && mkdir -p build && cd build && \
    cmake -DENABLE_PULL=OFF \
          -DENABLE_PUSH=OFF \
          -DUSE_THIRDPARTY_LIBRARIES=OFF \
          -DENABLE_TESTING=OFF \
          -DBUILD_SHARED_LIBS=OFF \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build and install cpr from source with optimizations
WORKDIR /tmp/cpr
RUN rm -rf build && mkdir -p build && cd build && \
    cmake -DCPR_BUILD_TESTS=OFF \
          -DCPR_BUILD_TESTS_SSL=OFF \
          -DCPR_FORCE_USE_SYSTEM_CURL=ON \
          -DBUILD_SHARED_LIBS=OFF \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Final runtime stage - minimal image
FROM ubuntu:22.04

# Prevent interactive prompts
ARG DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libcurl4 \
    zlib1g \
    libicu70 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/*

# Copy installed libraries (gRPC, protobuf, prometheus-cpp, cpr) from builder stage
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/include /usr/local/include

# Update library cache
RUN ldconfig

# Create non-root user for security
RUN useradd -m -s /bin/bash grpcuser

# Set working directory
WORKDIR /app

# Change ownership to non-root user
RUN chown -R grpcuser:grpcuser /app

# Switch to non-root user
USER grpcuser

# Default command
CMD ["/bin/bash"]