#include <grpc++/grpc++.h>
#include <list>

#include "common/status.h"
#include "proto/backtrace.grpc.pb.h"
#include "server/db.h"

namespace bt {

class Db;

// Service to seek points from the database
class Seeker : public proto::Seeker::Service {
public:
  Status Init(Db *db);

  grpc::Status
  GetUserTimeline(grpc::ServerContext *context,
                  const proto::GetUserTimelineRequest *request,
                  proto::GetUserTimelineResponse *response) override;

  grpc::Status
  GetUserNearbyFolks(grpc::ServerContext *context,
                     const proto::GetUserNearbyFolksRequest *request,
                     proto::GetUserNearbyFolksResponse *response) override;

private:
  Status BuildTimelineKeysForUser(uint64_t user_id,
                                  std::list<proto::DbKey> *keys);
  Status BuildTimelineForUser(const std::list<proto::DbKey> &keys,
                              proto::GetUserTimelineResponse *timeline);
  Status BuildKeysToSearchAroundPoint(uint64_t user_id,
                                      const proto::UserTimelinePoint &point,
                                      std::list<proto::DbKey> *keys);

  Status BuildLogicalBlock(
      const proto::DbKey &timelime_key, uint64_t user_id,
      std::vector<std::pair<proto::DbKey, proto::DbValue>> *user_entries,
      std::vector<std::pair<proto::DbKey, proto::DbValue>> *folk_entries);

  bool IsNearbyFolk(const proto::DbValue &user_value,
                    const proto::DbValue &folk_value);

  Db *db_ = nullptr;
};

} // namespace bt
