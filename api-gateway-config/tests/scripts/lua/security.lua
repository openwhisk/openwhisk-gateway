
-- Copyright (c) 2016 IBM. All rights reserved.
--
--   Permission is hereby granted, free of charge, to any person obtaining a
--   copy of this software and associated documentation files (the "Software"),
--   to deal in the Software without restriction, including without limitation
--   the rights to use, copy, modify, merge, publish, distribute, sublicense,
--   and/or sell copies of the Software, and to permit persons to whom the
--   Software is furnished to do so, subject to the following conditions:
--
--   The above copyright notice and this permission notice shall be included in
--   all copies or substantial portions of the Software.
--
--   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
--   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
--   DEALINGS IN THE SOFTWARE.

local fakengx = require 'fakengx'
local fakeredis = require 'fakeredis'
local oauth = require 'policies/security/oauth'
local cjson = require "cjson" 

describe('OAuth security module', function() 
  it('Exchanges a good secret', function ()
    local red = fakeredis.new() 
    local token = "test" 
    local ngxattrs = [[
      {
        "http_Authorization":"]] .. token .. [[",
        "tenant":"1234",
        "gatewayPath":"v1/test"
      }
    ]]
    local ngx = fakengx.new()
    ngx.var = cjson.decode(ngxattrs) 
    _G.ngx = ngx
    local securityObj = [[
      {
        "type":"oauth",
        "provider":"mock",
        "scope":"resource"
      }
    ]]
    local result = oauth.processWithRedis(red, cjson.decode(securityObj)) 
    assert.same(red:exists('oauth:providers:mock:tokens:test'), true)
    assert(result)
  end)
  it('Exchanges a bad token, doesn\'t cache it and returns false', function() 
    local red = fakeredis.new()   
    local token = "bad" 
    local ngxattrs = [[
      {
        "http_Authorization":"]] .. token .. [[",
        "tenant":"1234",
        "gatewayPath":"v1/test"
      }
    ]]
    local ngx = fakengx.new()
    ngx.var = cjson.decode(ngxattrs) 
    _G.ngx = ngx
    local securityObj = [[
      {
        "type":"oauth",
        "provider":"mock",
        "scope":"resource"
      }
    ]]
    local result = oauth.processWithRedis(red, cjson.decode(securityObj))
    assert.same(red:exists('oauth:providers:mock:tokens:bad'), false)
    assert.falsy(result)
  end)
end) 
