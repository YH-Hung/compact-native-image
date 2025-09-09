cmake_minimum_required(VERSION 3.16)
project(GreeterServer)

set(CMAKE_CXX_STANDARD 17)

find_package(Protobuf REQUIRED)
find_package(gRPC REQUIRED)

# Generate protobuf and gRPC files
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS greeter.proto)
set(GRPC_SRCS "${CMAKE_CURRENT_BINARY_DIR}/greeter.grpc.pb.cc")
set(GRPC_HDRS "${CMAKE_CURRENT_BINARY_DIR}/greeter.grpc.pb.h")

add_custom_command(
  OUTPUT "${GRPC_SRCS}" "${GRPC_HDRS}"
  COMMAND protoc
  ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
       --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
       -I "${CMAKE_CURRENT_SOURCE_DIR}"
       --plugin=protoc-gen-grpc=`which grpc_cpp_plugin`
       "${CMAKE_CURRENT_SOURCE_DIR}/greeter.proto"
  DEPENDS greeter.proto
)

add_executable(greeter_server
  greeter_server.cpp
  ${PROTO_SRCS}
  ${GRPC_SRCS}
)

target_include_directories(greeter_server PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

target_link_libraries(greeter_server
  protobuf::libprotobuf
  gRPC::grpc++
  /usr/local/lib/libutf8_range_lib.a
  /usr/local/lib/libutf8_validity.a
  /usr/local/lib/libabsl_utf8_for_code_point.a
)