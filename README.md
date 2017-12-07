# Name

lua-resty-17monip - lua 17monip client driver for the ngx_lua, see:[https://www.ipip.net/](https://www.ipip.net/ "https://www.ipip.net/")
# Status

This library is considered production ready.
# Description

This Lua library is a 17monip client driver for the ngx_lua nginx module:
# Synopsis

```
local cjson = require "cjson"
local ip17mon = require "resty.17monip"

local ip = ngx.var.remote_addr

local ip17m = ip17mon:new("/path/17monipdb.dat") -- or 17monipdb.datx

ngx.print(cjson.encode(ip17m:find(ip)))
```
# Requires

Lua Bit Operations Module, see:[http://bitop.luajit.org/](http://bitop.luajit.org/ "http://bitop.luajit.org/")

# TODO

# See Also

[https://github.com/ilsanbao/17moncn/tree/master/luajit](https://github.com/ilsanbao/17moncn/tree/master/luajit "https://github.com/ilsanbao/17moncn/tree/master/luajit")