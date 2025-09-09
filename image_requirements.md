# Functionality

- create a Dockerfile under compact_image to build a image as a base runtime of a c++ grpc server.
- this image should from ubuntu 22.04
- grpc and protobuf have to be installed through build from source. The source of grpc had already downloaded in grpc under current directory.

# Non-Functional Requirements

- You MUST adopt all possible approaches to reduce the image size.
- Testing: provide another image from the grpc base image you created, add a sample c++ grpc server, run the container, and verify server is working properly by making grpc call using grpcurl.