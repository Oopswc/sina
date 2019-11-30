local _M ={}
_M.hexstr="XEB2A38568661887FA180BDDB5CABD5F21C7BFD59C090CB2D245A87AC253062882729293E5506350508E7F9AA3BB77F4333231490F915F6D63C55FE2F08A49B353F444AD3993CACC02DB784ABBB8E42A9B1BBFFFB38BE18D78E87A0E41B9B8F73A928EE0CCEE1F6739884B9777E4FE9E88A1BBE495927AC4A799B3181D6442443"

_M.b2a_hex = function (str)
    local ss = ""
    for i = 1, string.len(str) do
        local charcode = tonumber(string.byte(str, i, i));
        local hexstr = string.format("%02X", charcode);
        ss = ss..hexstr
    end
    return ss
end

_M.makeNonce = function (len)
    local x = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local strlen = #x
    local str = ""
    for i=1,len do
        math.randomseed(string.reverse(tostring(ngx.now()*1000)))
        local pos = math.ceil(math.random()*1000000)%strlen
        str = str .. string.sub(x,pos,pos)
    end
    return str or "CG3WY1"
end

_M.makeRsa = function(tm,nonce,pw)
    --local pkey = require'openssl'.pkey   --https://github.com/zhaozg/lua-openssl
    --local bn = require'openssl'.bn       --https://github.com/zhaozg/lua-openssl
    local decstr = bn.number(_M.hexstr)
    --print(bn.tohex(decstr))
    --local hexstr ="165138424261149263963666229661164814908887524950166142962960019363944425161240370251403452452001165143400173133423045791330687304650944332950460079059702342999940532642226896299225258939028313437520982527474148958262129523279095471616009516621824844891755906467794220597075349492626446841979774101805104112707"
    pubkey = pkey.new({alg='rsa',n=decstr,e=65537})
    --local tb = (pkey.get_public(pubkey)):parse()
    local pw_string = tm .. '\t' .. nonce .. '\n' .. pw
    local sp = pkey.encrypt(pubkey,pw_string)
    local encypted_str = _M.b2a_hex(sp) 
    return(string.lower(encypted_str))
end

return _M
