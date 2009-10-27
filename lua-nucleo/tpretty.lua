-- tpretty.lua -- pretty visualization of non-recursive tables.
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local pairs, ipairs, type, tostring = pairs, ipairs, type, tostring
local table_concat = table.concat
local string_match, string_format = string.match, string.format


local lua51_keywords = import 'lua-nucleo/language.lua' { 'lua51_keywords' }
local create_prettifier = import 'lua-nucleo/prettifier.lua' { 'create_prettifier' }

local tpretty
do
  local add=""
  local function impl(t, cat, prettifier, visited)
    local t_type = type(t)
    if t_type == "table" then
      if not visited[t] then
        visited[t] = true

	prettifier:table_start()

        -- Serialize numeric indices

        for i, v in ipairs(t) do
          if i > 1 then -- TODO: Move condition out of the loop
	    prettifier:separator()
          end
          impl(v, cat, prettifier, visited)
        end

        local next_i = #t + 1

        -- Serialize hash part
        -- Skipping comma only at first element if there is no numeric part.
        local need_comma = (next_i > 1)
        for k, v in pairs(t) do
          local k_type = type(k)
          if k_type == "string" then
	    if need_comma then
	      prettifier:separator()
	    end
	    need_comma = true
	    prettifier:key_start()
            -- TODO: Need "%q" analogue, which would put quotes
            --       only if string does not match regexp below
            if not lua51_keywords[k] and string_match(k, "^[%a_][%a%d_]*$") then
              cat(k)
            else
              cat(string_format("[%q]", k))
            end
	    prettifier:value_start()
            impl(v, cat, prettifier, visited)
	    prettifier:key_value_finish()
          else
            if
              k_type ~= "number" or -- non-string non-number
              k >= next_i or k < 1 or -- integer key in hash part of the table
              k % 1 ~= 0 -- non-integer key
            then
	      if need_comma then
		prettifier:separator()
	      end
	      need_comma = true
	      prettifier:key_start()
              cat("[")
              impl(k, cat, prettifier, visited)
              cat("]")
	      prettifier:value_start()
              impl(v, cat, prettifier, visited)
	      prettifier:key_value_finish()
            end
          end
        end
	prettifier:table_finish()

        visited[t] = nil
      else
        -- Note this loses information on recursive tables
        cat('"table (recursive)"')
      end
    elseif t_type == "number" or t_type == "boolean" then
      cat(tostring(t))
    elseif t == nil then
      cat("nil")
    else
      -- Note this converts non-serializable types to strings
      cat(string_format("%q", tostring(t)))
    end
  end

  tpretty = function(t, indent, cols)
    local buf = {}
    local sptable = {};
    local cat = function(v) buf[#buf + 1] = v end
    local pr = create_prettifier(indent, buf, cols)
    impl(t, cat, pr, {})
    pr:finished()
    return table_concat(buf)
  end
end

return
{
  tpretty = tpretty;
}