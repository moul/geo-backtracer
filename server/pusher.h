#include <atomic>
#include <grpcpp/grpcpp.h>
#include <rocksdb/db.h>

#include "common/status.h"
#include "proto/backtrace.grpc.pb.h"
#include "server/db.h"

namespace bt {

class Db;

// Service to push points to the database, see threading notes above,
// there is only one thread accepting requests and writing to the
// database in batches.
class Pusher : public proto::Pusher::Service {
public:
  Status Init(Db *db);

  grpc::Status PutLocation(grpc::ServerContext *context,
                           const proto::PutLocationRequest *request,
                           proto::PutLocationResponse *response) override;

private:
  Status PutTimelineLocation(const proto::Location &location);
  Status PutReverseLocation(const proto::Location &location);

  Db *db_ = nullptr;

  std::atomic<uint64_t> counter_ok_ = 0;
  std::atomic<uint64_t> counter_ko_ = 0;
};

} // namespace bt
