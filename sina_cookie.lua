local args =util.get_args()
local account = args.account or "XXX"
local passwd = args.passwd or "XXXX"

local tm = ngx.time()
local sina = require("sina_rsa")
local nonce = sina.makeNonce(6)
local su = ngx.encode_base64(account)
local sp = sina.makeRsa(tm,nonce,passwd)
local post_data ={}
post_data.entry="sso"
post_data.gateway=1
post_data.from="null"
post_data.savestate=0
post_data.useticket=0
post_data.service="sso"
post_data.pagerefer=""
post_data.vnsf=1
post_data.pwencode="rsa2"
post_data.rsakv="1330428213"
post_data.sr="1920*1080"
post_data.encoding="UTF-8"
post_data.cdult=3
post_data.domain="sina.com.cn"
post_data.prelt=120
post_data.returntype="TEXT"
post_data.su=su
post_data.servertime=tm
post_data.nonce=nonce
post_data.sp=sp

local post_list = {}
for k,v in pairs(post_data) do
    table.insert(post_list,k.."="..v)
end
local body_str = table.concat(post_list,"&")

-- send http request
local headers = {}
headers["User-Agent"] = 'Mozilla/5.0 (Windows NT 10.0; WOW64)"" AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.76 Safari/537.36'
headers["Content-Type"] = 'application/x-www-form-urlencoded'
headers["Origin"] = 'https://login.sina.com.cn'
headers["Referer"] = 'https://login.sina.com.cn/signup/signin.php?entry=sso'

-- method one
local httpc = http_v2.new()
local target_url = "https://login.sina.com.cn/sso/login.php?client=ssologin.js(v1.4.15)" 
local res ,err = httpc:request_uri(target_url,{headers=headers,method="POST",body=body_str,ssl_verify=false})
if err then
    nlog.info(err)
    ngx.exit(406)
end


-- method two
--[[
local args = {}
args["client"] = "ssologin.js(v1.4.15)"

ngx.req.set_header("User-Agent",headers["User-Agent"])
ngx.req.set_header("Content-Type",headers["Content-Type"])
ngx.req.set_header("Content-Length",headers["Content-Length"])
ngx.req.set_header("Origin",headers["Origin"])
ngx.req.set_header("Referer",headers["Referer"])

local res = ngx.location.capture("/internal/sina_cookie",{args=args,method=ngx.HTTP_POST,body=body_str})

if tonumber(res.status) ~= 200 then
    ngx.exit(res.status)
end
--]]


local body = res.body
if res["headers"]["Content-Encoding"] == "gzip" then
    local unzip=zip.inflate() 
    body = unzip(res.body)
end

local ret = {}
local cookie_str =""
if nil == string.find(body,"crossDomainUrlList") then
    ret.ret = "500" 
    ret.body = cjson.decode(body)
else
    local headers = res.headers
    -- get cookie       https://github.com/cloudflare/lua-resty-cookie
    local cookie = headers["Set-Cookie"]
    ret.ret="200"
    ret.data = cjson.decode(body)
    ret.cookie = cookie
    for _,v in pairs(cookie) do
        cookie_str = cookie_str .. string.match(v,"^[^;]*;") 
    end
    ret.cookie_str = cookie_str
    -- redis_util.string_set(redsrv,"cookie","sina",cookie_str,86400)
end

ngx.header.content_type="text/plain"
ngx.print(cjson.encode(ret))
ngx.exit(200)
