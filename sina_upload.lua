local args =util.get_args()
local timeout = tonumber(args.timeout) or 2000

-- body
local jpg_data = util.get_body()
local boundary = "WebKitFormBoundaryOi0aYCHDVTjM6vGy"
local _start =  "--" .. boundary .. 
            '\r\nContent-Disposition: form-data; name="pic1"; \r\n\r\n'
local _end ='\r\n--'..boundary..'--\r\n'
local body_str = _start .. jpg_data .._end

-- headers
local headers = {}
headers["User-Agent"] = util.get_ua() 
headers["Content-Type"] =  "multipart/form-data;boundary=" .. boundary
headers["Content-Length"] = #body_str
-- header cookie
local cookie = redis_util.string_get(redsrv,"cookie","sina")
if nil ~= cookie then
    headers["Cookie"] = cookie
else
    ngx.location.capture("/sina_cookie")
    local cookie = redis_util.string_get(redsrv,"cookie","sina")
    headers["Cookie"] = cookie
end

-- url params
local args = {}
args["ori"] = 1
args["mime"] = "image/jpeg"
args["data"] = "base64"
args["url"] = 0
args["markpos"] = 1
args["logo"] = ""
args["nick"] = ""
args["marks"] = 1
args["app"] = "miniblog"
args["cb"] = "http://weibo.com/aj/static/upimgback.html?_wv=5&callback=STK_ijax_" .. math.ceil(ngx.now()*1000)

nlog.info(cjson.encode(headers))

-- method one
local httpc = http_v2.new()
if proxy then
    local target_url = "http://picupload.service.weibo.com/interface/pic_upload.php?" .. ngx.encode_args(args)
    local proxy_uri = "127.0.0.1:9600"                  -- set yours proxy
    local http_proxy = "http://"..proxy_uri
    httpc:set_proxy_options({http_proxy = http_proxy})
    httpc:set_timeouts(timeout,timeout,timeout)
end

local res ,err = httpc:request_uri(target_url,{headers=headers,method="POST",body=body_str,ssl_verify=false})
if err then
    nlog.info(cjson.encode(res.body) .. tostring(err))
    ngx.exit(500)
end

--[[
-- method two
ngx.req.set_header("User-Agent",headers["User-Agent"])
ngx.req.set_header("Content-Type",headers["Content-Type"])
ngx.req.set_header("Content-Length",headers["Content-Length"])
ngx.req.set_header("Cookie",headers["Cookie"])

local res = ngx.location.capture("/internal/sina_upload",{args=args,method=ngx.HTTP_POST,body=body_str})
if res.status ~= 200 then
    ngx.exit(res.status)
end
--]]

local result = res.body:gsub("^[^{]*({.-})","%1") 
local pid,num = result:gsub('^.-"pid":"(.-)".-$',"%1")
local width = result:gsub('^.-"width":(.-)[,}].-$',"%1")
local height = result:gsub('^.-"height":(.-)[,}].-$',"%1")
local size = result:gsub('^.-"size":(.-)[,}].-$',"%1")

local msg = {}
if num == 1 then
    msg.pid=pid
    msg.width=width
    msg.height=height
    msg.size=size
else
    msg.pid="No pid or upload error"
end

ngx.print(cjson.encode(msg))
ngx.exit(200)
