docker build . -t "Redis-stack-server"
docker run -d --name redis-stack \
        -p 6379:6379 \
        -e REDIS_ARGS="--requirepass mypassword" \
        -v ./local-data/:/data \
        Redis-stack-server
# Custon conf volume
# #-v `pwd`/local-redis-stack.conf:/redis-stack.conf
# Env Variables
# To pass in arbitrary configuration changes, you can set any of these environment variables:

# REDIS_ARGS: extra arguments for Redis
# REDISEARCH_ARGS: arguments for RediSearch
# REDISJSON_ARGS: arguments for RedisJSON
# REDISGRAPH_ARGS: arguments for RedisGraph
# REDISTIMESERIES_ARGS: arguments for RedisTimeSeries
# REDISBLOOM_ARGS: arguments for RedisBloom
docker exec -it redis-stack redis-cli