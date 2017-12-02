-- Copyright (C) 2015 Yunfeng Meng
-- 参考: https://github.com/ChiChou/node-ipip

local bit          = require("bit")
local lshift       = bit.lshift
local rshift       = bit.rshift
local band         = bit.band
local str_byte     = string.byte
local io_open      = io.open
local pow          = math.pow
local str_match    = string.match
local str_gmatch   = string.gmatch
local str_sub      = string.sub
local str_find     = string.find
local tbl_insert   = table.insert
local type         = type
local setmetatable = setmetatable


local _M = { _VERSION = '0.01' }
local mt = { __index = _M }


local function byte_to_uint32(a, b, c, d)
    local _int = 0
    if a then
        _int = _int +  lshift(a, 24)
    end
    _int = _int + lshift(b, 16)
    _int = _int + lshift(c, 8)
    _int = _int + d
    if _int >= 0 then
        return _int
    else
        return _int + pow(2, 32)
    end
end


local ipip = {
    dat = {
        data_buffer  = "", -- ipip数据缓存
        index_buffer = "", -- ipip索引缓存
        offset_len   = 0,
    },
    datx = {
        data_buffer  = "",
        index_buffer = "",
        offset_len   = 0,
    }
}


local function _find(self, ip)
    local ip1, ip2, ip3, ip4 = str_match(ip, "(%d+).(%d+).(%d+).(%d+)")
    if ip1 == nil then
        return nil
    end
    local ip_uint32 = byte_to_uint32(ip1, ip2, ip3, ip4)
    
    local ext = self.VERSION_EXT
    if ipip[ext].data_buffer == "" then
        local file = io_open(self.dat_file, "r")
        if file == nil then
            return nil
        end
        
        ipip[ext].data_buffer = file:read("*a") -- io blocking
        if ipip[ext].data_buffer == nil then
            return nil
        end
        
        local str = str_sub(ipip[ext].data_buffer, 1, 4)
        
        ipip[ext].offset_len   = byte_to_uint32(str_byte(str, 1), str_byte(str, 2),str_byte(str, 3),str_byte(str, 4))
        ipip[ext].index_buffer = str_sub(ipip[ext].data_buffer, 5, ipip[ext].offset_len)
        
        file:close()
    end
    
    local tmp_offset   = rshift(band(ip_uint32, self.PARTITION_MASK), self.PARTITION_FACTOR)
    local start_len    = byte_to_uint32(str_byte(ipip[ext].index_buffer, tmp_offset + 4), str_byte(ipip[ext].index_buffer, tmp_offset + 3), str_byte(ipip[ext].index_buffer, tmp_offset + 2), str_byte(ipip[ext].index_buffer, tmp_offset + 1))
    local max_comp_len = ipip[ext].offset_len - self.HEADER_SIZE - 4
    local start        = start_len * self.BLOCK_SIZE + self.HEADER_SIZE + 1
    local find_uint32  = 0
    local index_offset = -1
    local index_length = -1
    
    while start < max_comp_len do
        find_uint32 = byte_to_uint32(str_byte(ipip[ext].index_buffer, start), str_byte(ipip[ext].index_buffer, start + 1),str_byte(ipip[ext].index_buffer, start + 2),str_byte(ipip[ext].index_buffer, start + 3))
        if ip_uint32 <= find_uint32  then
            index_offset = byte_to_uint32(0, str_byte(ipip[ext].index_buffer, start + 6),str_byte(ipip[ext].index_buffer, start + 5),str_byte(ipip[ext].index_buffer, start + 4))
            index_length = str_byte(ipip[ext].index_buffer, start + self.LEN_OFFSET)
            break
        end
        start = start + self.BLOCK_SIZE
    end
  
    if index_offset == -1 or index_length == -1 then
        return nil
    end
    
    local offset = ipip[ext].offset_len + index_offset - self.HEADER_SIZE
    local location = str_sub(ipip[ext].data_buffer, offset + 1, offset + index_length)

    if type(location) == "string" and location ~= "" then
        local result    = {}
        for match in (location .. "\t"):gmatch("(.-)\t") do
            tbl_insert(result, match)
        end
        return result -- https://www.ipip.net/api.html
    end
    return nil
end


function _M.new(self, dat_file)
    dat_file = dat_file or "./17monipdb.dat"

    return setmetatable({dat_file = dat_file}, mt)
end


function _M.find(self, ip)
    self.HEADER_SIZE      = 0x400
    self.BLOCK_SIZE       = 8
    self.LEN_OFFSET       = 7
    self.PARTITION_MASK   = 0xFF000000
    self.PARTITION_FACTOR = 22
    self.VERSION_EXT      = 'dat'
    return _find(self, ip)
end


function _M.findx(self, ip)
    self.HEADER_SIZE      = 0x40000
    self.BLOCK_SIZE       = 9
    self.LEN_OFFSET       = 8
    self.PARTITION_MASK   = 0xFFFF0000
    self.PARTITION_FACTOR = 14
    self.VERSION_EXT      = 'datx'
    return _find(self, ip)
end


return _M

