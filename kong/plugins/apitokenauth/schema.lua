--
-- Created by IntelliJ IDEA.
-- User: shanyechen
-- Date: 2018/3/30
-- Time: 下午12:55
-- To change this template use File | Settings | File Templates.
--
return {
    no_consumer = true,
    fields = {

        validate_header_key = {type = "string", required = true, default = "userId"},
        validate_header_value = {type = "string", required = true, default = "token"},

        redis_host = {type = "string", required = true, default = "codis-proxy.codis-ns"},
        redis_port = {type = "number", required = true, default = 6379 },
        redis_pool_size = {type = "number", required = true, default = 100 },
        redis_pool_max_idle_time={type = "number", required = true, default = 10000 },

        cacheKey_prefix = {type = "string", required = true, default = "user:"},
        cacheKey_suffix = {type = "string", required = true, default = ":token" },


        auth_server_url = {type = "string", required = true, default = "http://user-auth.user-ns" }
    }
}

