--
-- Date: 2018/3/29
-- Time: 下午6:16
--


local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local CustomHandler = BasePlugin:extend()
local http = require "socket.http"


function CustomHandler:new()
    CustomHandler.super.new(self, "apitokenauth")
end


-- 连接池大小是100个，并且设置最大的空闲时间是 10 秒
local function close_redis(red)
    if not red then
        return
    end
    --释放连接(连接池实现)
    local pool_max_idle_time = 10000 --毫秒 10秒
    local pool_size = 100 --连接池大小
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
    if not ok then
        --ngx.say("set reids keepalive error : ", err)
        ngx.log(ngx.ERR,"set reids keepalive error : ", err)
    end
end




local function requestApiValidateToken(userId,token,config)

    local req_args=config.validate_header_key.."="..userId.."&"..config.validate_header_value.."="..token
    local response_body = {}

    local res, code, response_headers = http.request{
        url = config.auth_server_url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded";
            ["Content-Length"] = #req_args;
        },
        source = ltn12.source.string(req_args),
        sink = ltn12.sink.table(response_body),
    }

    return code;

end







local function validate_token(userId,token,config)

    if userId ~= nil and token~=nil then

        -- ngx.say("userId: ", userId)
        -- ngx.say("token: ", token)

        local redis = require "resty.redis"
        local red = redis:new()
        red:set_timeout(1000)   --  1 sec


        local ok, err = red:connect(config.redis_host, config.redis_port)

        if not ok then
            --ngx.say("failed to connect: ", err)
            ngx.log(ngx.ERR, "failed to connect redis:  ", err)

            -- redis 连接失败 采用 后端接口验证

            local code=requestApiValidateToken(userId,token,config)

            if code ~= 200 then  -- 当code不为200则 token 已经完全失效(已经重现登录数据库中token已经刷新)
                return responses.send(200, {result="",code=902,ts=ngx.now()*1000})
            else
                return  -- 成功验证返回
            end

        else


            local userRedisToken, err = red:get(config.cacheKey_prefix..userId..config.cacheKey_suffix)

            close_redis(red)

            if userRedisToken ~= ngx.null then

                if  userRedisToken == token then

                    -- token是正确 调用后端api
                    return -- 成功验证返回

                else
                    -- token是错误 返回错误json
                    return responses.send(200, {result="",code=901,ts=ngx.now()*1000})

                end

            else

                -- token 不在redis 中,调用gRPC 后端验证token服务 从mysql 中判断

                local code=requestApiValidateToken(userId,token,config)

                if code ~= 200 then  -- 当code不为200则 token 已经完全失效(已经重现登录数据库中token已经刷新)
                    return responses.send(200, {result="",code=902,ts=ngx.now()*1000})
                end


            end



        end


    else

        -- 请求没有传入没有userId或token
        --ngx.say("请求没有传入没有userId或token")
        --return responses.send(200, "Missing token")

        return responses.send(200, {result="",code=900,ts=ngx.now()*1000})

    end


end




function CustomHandler:access(config)
    -- Eventually, execute the parent implementation
    -- (will log that your plugin is entering this context)
    CustomHandler.super.access(self)

    -- Implement any custom logic here


    ngx.header['Content-Type']="text/html;charset=UTF-8"

    local headers = ngx.req.get_headers()

    local userId=headers[config.validate_header_key]
    local token=headers[config.validate_header_value]


    validate_token(userId,token,config)

end



CustomHandler.PRIORITY = 1006 --高于jwt

return CustomHandler



























