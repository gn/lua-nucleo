-- table-utils.lua: small table utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local setmetatable, error, pairs, ipairs, tostring, select =
      setmetatable, error, pairs, ipairs, tostring, select

-- Warning: it is possible to corrupt this with rawset and debug.setmetatable.
local empty_table = setmetatable(
    { },
    {
      __newindex = function(t, k, v)
        error("attempted to change the empty table", 2)
      end;

      __metatable = "empty_table";
    }
  )

local function toverride_many(t, s, ...)
  if s then
    for k, v in pairs(s) do
      t[k] = v
    end
    -- Recursion is usually faster than calling select()
    return toverride_many(t, ...)
  end

  return t
end

local function tappend_many(t, s, ...)
  if s then
    for k, v in pairs(s) do
      if t[k] == nil then
        t[k] = v
      else
        error("attempted to override table key `" .. tostring(k) .. "'", 2)
      end
    end

    -- Recursion is usually faster than calling select()
    return tappend_many(t, ...)
  end

  return t
end

-- Keys are ordered in undetermined order
local tkeys = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[#r + 1] = k
  end

  return r
end

-- Values are ordered in undetermined order
local tvalues = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[#r + 1] = v
  end

  return r
end

-- Keys and values are ordered in undetermined order
local tkeysvalues = function(t)
  local keys, values = { }, { }

  for k, v in pairs(t) do
    keys[#keys + 1] = k
    values[#values + 1] = v
  end

  return keys, values
end

-- If table contains multiple keys with the same value,
-- only one key is stored in the result, picked in undetermined way.
local tflip = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = k
  end

  return r
end

-- If table contains multiple keys with the same value,
-- only the last such key (highest one) is stored in the result.
local tiflip = function(t)
  local r = { }

  for i = 1, #t do
    r[t[i]] = i
  end

  return r
end

local tset = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = true
  end

  return r
end

local tiset = function(t)
  local r = { }

  for i = 1, #t do
    r[t[i]] = true
  end

  return r
end

local function tiinsert_args(t, a, ...)
  if a ~= nil then
    t[#t + 1] = a
    -- Recursion is usually faster than calling select() in a loop.
    return tiinsert_args(t, ...)
  end

  return t
end

local timap_inplace = function(fn, t, ...)
  for i = 1, #t do
    t[i] = fn(t[i], ...)
  end

  return t
end

local timap_sliding = function(fn, t, ...)
  local r = {}

  for i = 1, #t do
    tiinsert_args(r, fn(t[i], ...))
  end

  return r
end

local tiwalk = function(fn, t, ...)
  for i = 1, #t do
    fn(t[i], ...)
  end
end

local tiwalker = function(fn)
  return function(t)
    for i = 1, #t do
      fn(t[i])
    end
  end
end

local tequals = function(lhs, rhs)
  for k, v in pairs(lhs) do
    if v ~= rhs[k] then
      return false
    end
  end

  for k, v in pairs(rhs) do
    if lhs[k] == nil then
      return false
    end
  end

  return true
end

local tiunique = function(t)
  return tkeys(tiflip(t))
end

local tgenerate_n = function(n, generator, ...)
  local r = { }
  for i = 1, n do
    r[i] = generator(...)
  end
  return r
end

local taccumulate = function(t, init)
  local sum = init or 0
  for k, v in pairs(t) do
    sum = sum + v
  end
  return sum
end

local tnormalize, tnormalize_inplace
do
  local impl = function(t, r, sum)
    sum = sum or taccumulate(t)

    for k, v in pairs(t) do
      r[k] = v / sum
    end

    return r
  end

  tnormalize = function(t, sum)
    return impl(t, { }, sum)
  end

  tnormalize_inplace = function(t, sum)
    return impl(t, t, sum)
  end
end

return
{
  empty_table = empty_table;
  toverride_many = toverride_many;
  tappend_many = tappend_many;
  tkeys = tkeys;
  tvalues = tvalues;
  tkeysvalues = tkeysvalues;
  tflip = tflip;
  tiflip = tiflip;
  tset = tset;
  tiset = tiset;
  tiinsert_args = tiinsert_args;
  timap_inplace = timap_inplace;
  timap_sliding = timap_sliding;
  tiwalk = tiwalk;
  tiwalker = tiwalker;
  tequals = tequals;
  tiunique = tiunique;
  tgenerate_n = tgenerate_n;
  taccumulate = taccumulate;
  tnormalize = tnormalize;
  tnormalize_inplace = tnormalize_inplace;
}
