local pgmoon = require("pgmoon")
local db_credentials = require("db_credentials")
local ngx = ngx

local db = {}

function decode_resp(resp)
  -- Example resp: '(200,"{\"errors\": []}")'
  
  local first_comma_index = string.find(resp, ',')

  if first_comma_index == nil then
    return 500, nil
  end

  local status_code = tonumber(string.sub(resp, 2, first_comma_index - 1))
  local unescaped_json = string.sub(resp, first_comma_index + 2, string.len(resp) - 2)

  -- JSON strings end up being double-quoted, e.g. ""user"": {""email"": ... }
  local escaped_json = string.gsub(unescaped_json, "\"\"", "\"")
  
  return status_code, escaped_json
end

function db.select(name, arg)
  local pg = pgmoon.new(db_credentials)

  assert(pg:connect())
  result, err, partial, num_queries = pg:query(
    "SELECT " .. name .. "(" .. pg:escape_literal(arg) .. ");"
  )

  pg:keepalive()
  pg = nil

  if result == nil then
    return 500, nil, err, partial, num_queries 
  end

  status_code, json = decode_resp(result[1][name])

  return status_code, json, err, partial, num_queries
end

function db.post(name)
  if ngx.req.get_method() ~= "POST" then
    ngx.status = 404
    return ngx.exit(404)
  end

  ngx.req.read_body()

  return db.respond(name, ngx.req.get_body_data())
end

function db.get(name, arg)
  if ngx.req.get_method() ~= "GET" then
    ngx.status = 404
    return ngx.exit(404)
  end

  return db.respond(name, arg)
end

function db.respond(name, arg)
  status_code, json, err, partial, num_queries = db.select(name, arg)

  ngx.status = status_code

  if json ~= nil then
    ngx.print(json)
  end

  return ngx.exit(ngx.OK)
end

return db
