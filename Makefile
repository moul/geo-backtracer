# Covid Backtracer.
#
# For now, all-in-one binary; this is meant to be split at some point.

CXXFLAGS = -g -Wno-deprecated-declarations -Wall -std=c++17 $(shell freetype-config --cflags) -Iserver -I.
LDLIBS = -lglog -lgflags -lrocksdb -lboost_filesystem -lgrpc++ -lprotobuf

SERVER := bin/bt_server
CLIENT := bin/bt_client
TEST   := bin/bt_test
CXX    := clang++
FMT    := clang-format
PBUF   := protoc

SRCS := $(filter-out $(wildcard server/*test.cc), $(wildcard server/*.cc))
OBJS := $(SRCS:.cc=.o)
DEPS := $(OBJS:.o=.d)

SRCS_TEST := $(filter-out server/main.cc, $(wildcard server/*.cc))
OBJS_TEST := $(SRCS_TEST:.cc=.o)
DEPS_TEST := $(OBJS_TEST:.o=.d)

SRCS_PB   := $(wildcard proto/*.proto)
OBJS_PB   := $(SRCS_PB:.proto=.pb.o)
GENS_PB   := $(SRCS_PB:.proto=.pb.cc) $(PROTOS:.proto=.pb.h)

SRCS_GRPC := $(wildcard proto/*.proto)
OBJS_GRPC := $(SRCS_PB:.proto=.grpc.pb.o)
GENS_GRPC   := $(SRCS_PB:.proto=.grpc.pb.cc) $(PROTOS:.proto=.pb.grpc.h)

SRCS_CLIENT := $(wildcard client/*.cc)
OBJS_CLIENT := $(SRCS_CLIENT:.cc=.o)
DEPS_CLIENT := $(OBJS_CLIENT:.o=.d)

.PHONY: all clean re test fmt help run inject server client

help:
	@echo "Help for Covid Backtracer:"
	@echo ""
	@echo "\033[1;31mThis is not production ready, some commands here are destructive.\033[0m"
	@echo ""
	@echo "make		# this message"
	@echo "make all	# build everything"
	@echo "make test	# run unit tests"
	@echo "make clean	# clean all build artifacts"
	@echo "make re		# rebuild covid backtracer"
	@echo "make server	# run a local instance of covid backtracer"
	@echo "make client	# inject fixtures into local instance"
	@echo ""

all: $(SERVER) $(TEST)

fmt:
	$(FMT) -i -style Chromium $(SRCS)

clean:
	rm -rf $(OBJS) $(DEPS) $(SERVER)
	rm -rf $(OBJS_TEST) $(DEPS_TEST) $(TEST)
	rm -rf $(GENS_PB) $(OBJS_PB)
	rm -rf $(GENS_GRPC) $(OBJS_GRPC)
	rm -rf $(OBJS_CLIENT) $(DEPS_CLIENT)

bin:
	mkdir -p bin

re: clean all

$(SERVER): bin $(OBJS) $(OBJS_PB) $(OBJS_GRPC)
	$(CXX) $(OBJS) $(OBJS_PB) $(OBJS_GRPC) $(LDLIBS) -o $@

$(CLIENT): bin $(OBJS_CLIENT) $(OBJS_PB)
	$(CXX) $(OBJS_CLIENT) $(OBJS_PB) $(LDLIBS) -o $@

$(TEST): bin $(OBJS_TEST) $(OBJS_PB) $(OBJS_GRPC)
	$(CXX) $(OBJS_TEST) $(OBJS_PB) $(OBJS_GRPC) $(LDLIBS) -lgtest -o $@

%.o: %.cc
	$(CXX) $(CXXFLAGS) -MMD -MP -c $< -o $@

%.grpc.pb.cc: %.proto
	$(PBUF) --grpc_out=. --plugin=protoc-gen-grpc=$(shell which grpc_cpp_plugin) $<

%.pb.cc: %.proto
	$(PBUF) --cpp_out=. $<

%.pb.o : %.pb.cc
	$(CXX) $(CXX_FLAGS) -c -o $@ $<

server: $(SERVER)
	$(SERVER)

test: $(TEST)
	$(TEST)

client: $(CLIENT)
	$(CLIENT)

-include $(DEPS)
-include $(DEPS_TEST)
