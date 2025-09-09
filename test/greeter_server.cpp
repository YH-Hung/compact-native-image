#include <iostream>
#include <memory>
#include <string>
#include <thread>
#include <chrono>
#include <fstream>
#include <sstream>

#include <grpcpp/grpcpp.h>
#include <prometheus/counter.h>
#include <prometheus/histogram.h>
#include <prometheus/registry.h>
#include <prometheus/text_serializer.h>
#include "greeter.grpc.pb.h"

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using helloworld::HelloRequest;
using helloworld::HelloReply;
using helloworld::Greeter;

// Global prometheus registry and metrics
auto registry = std::make_shared<prometheus::Registry>();

auto& request_counter = prometheus::BuildCounter()
    .Name("grpc_requests_total")
    .Help("Total number of gRPC requests")
    .Register(*registry);

auto& response_time_histogram = prometheus::BuildHistogram()
    .Name("grpc_request_duration_seconds")
    .Help("gRPC request duration in seconds")
    .Register(*registry);

// Simple HTTP server for metrics
void serve_metrics() {
    while (true) {
        std::this_thread::sleep_for(std::chrono::seconds(10));
        
        // Serialize metrics
        prometheus::TextSerializer serializer;
        std::ostringstream stream;
        serializer.Serialize(stream, registry->Collect());
        
        // Write to file that can be served by external HTTP server if needed
        std::ofstream file("/tmp/metrics.txt");
        if (file.is_open()) {
            file << stream.str();
            file.close();
        }
        
        std::cout << "Metrics updated at /tmp/metrics.txt" << std::endl;
        std::cout << "Current metrics:" << std::endl;
        std::cout << stream.str() << std::endl;
    }
}

class GreeterServiceImpl final : public Greeter::Service {
  Status SayHello(ServerContext* context, const HelloRequest* request,
                  HelloReply* reply) override {
    auto start_time = std::chrono::high_resolution_clock::now();
    
    // Increment request counter
    request_counter.Add({}).Increment();
    
    std::string prefix("Hello ");
    reply->set_message(prefix + request->name());
    
    // Record response time
    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);
    
    // Default histogram buckets for response time in seconds: 0.001, 0.01, 0.1, 1.0, 10.0
    static auto bucket_boundaries = prometheus::Histogram::BucketBoundaries{0.001, 0.01, 0.1, 1.0, 10.0};
    response_time_histogram.Add({}, bucket_boundaries).Observe(duration.count() / 1000000.0);
    
    return Status::OK;
  }
};

void RunServer() {
  // Start metrics background thread
  std::thread metrics_thread(serve_metrics);
  metrics_thread.detach();
  std::cout << "Metrics thread started - metrics will be updated every 10 seconds" << std::endl;
  
  std::string server_address("0.0.0.0:50051");
  GreeterServiceImpl service;

  ServerBuilder builder;
  builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
  builder.RegisterService(&service);
  std::unique_ptr<Server> server(builder.BuildAndStart());
  
  std::cout << "gRPC server listening on " << server_address << std::endl;
  server->Wait();
}

int main(int argc, char** argv) {
  RunServer();
  return 0;
}