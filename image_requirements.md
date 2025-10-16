# Functionality

- create a Dockerfile under compact-native-image to build a image as a base runtime of a c++ grpc server.
- this image should from ubuntu 22.04
- Rquired to be installed libraries listed below.

## gRPC

grpc and protobuf have to be installed through build from source. The source of grpc had already downloaded in the grpc folder under current directory.

## Promenteus-cpp

The source of prometheus-cpp had already downloaded in the prometheus-cpp foler under current directory.

## International Components for Unicode (ICU) Library

icu4c should be installed through package manager.

## libcpr

The source of cpr library had already downloaded in the cpr folder under current directory.

# Non-Functional Requirements

- You MUST adopt all possible approaches to reduce the image size.

# Testing

Provide another image from the grpc base image you created, add a sample c++ grpc server. run the container, and verify server is working properly by making grpc call using grpcurl.

This sample c++ grpc server should adopt prometheus-cpp to export metrics at /metrics

- including request counter and response time histogram.
- verify metrics exposure by visit the metrics endpoint and assert the metrics exported.