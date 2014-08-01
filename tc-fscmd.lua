-- Copyright (c) 2014 Travis Cross <tc@traviscross.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

require "tc-util"

local out
if stream then out=function(x) stream:write(x) end else out=print end

function usage(state,help)
  local p=""
  if state and state.prefix then
    p=table.join(state.prefix," ").." " end
  local a=""
  if state and state.alt and #state.alt>0 then
    if help and #help>0 then a="|" end
    a=a..table.join(state.alt,"|")
  end
  if help:match(" ") and #a>0 then help="("..help..")" end
  out("-ERR Usage: "..p..help..a.."\n")
end

function ok(data)
  if data then data=" "..data else data="" end
  out("+OK"..data.."\n")
end

function err(data)
  if data then data=" "..data else data="" end
  out("-ERR"..data.."\n")
end

function cmd_dispatch(cmd_tree,argv)
  if #argv == 0 then argv={""} end
  for i=#argv,1,-1 do
    local cmd,argl = table.splice(argv,i)
    local x,rem,node = tree.get(cmd_tree, cmd)
    local state={prefix=cmd,alt=table.keys(rem)}
    if i==1 and not x and not rem then
      return usage({},table.join(table.keys(node),"|"))
    elseif not x and rem then
      return usage(state,"")
    elseif x and type(x) == "function" then
      return x(state,table.unpack(argl))
    elseif x and type(x) == "table" then
      local validate=x[2]
      if validate then
        if type(validate) ~= "function" then
          return err("internal error; expected validator")
        end
        if not validate(state,table.unpack(argl)) then return end
      end
      local fn=x[1]
      if not fn or type(fn) ~= "function" then
        return err("internal error; expected function")
      end
      return fn(state,table.unpack(argl))
    end
  end
end

function make_validator(nrequired,help)
  return function(state,...)
    local rest={...}
    if #rest<nrequired then
      return usage(state,help)
    end
    return true
  end
end
