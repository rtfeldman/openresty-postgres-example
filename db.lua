local pgmoon = require("pgmoon")
local cjson = require("cjson")
local db_credentials = require("db_credentials")

local db = {}

function db.call(name, arg)
  local pg = pgmoon.new(db_credentials)

  assert(pg:connect())
  result, err, partial, num_queries = pg:query(
    "CALL " .. name .. "(" .. pg:escape_literal(arg) .. ");"
  )

  pg:keepalive()
  pg = nil

  if result ~= nil then
    result = cjson.encode(result[1][name])
  end

  return result, err, partial, num_queries
end

function db.select(name, arg)
  local pg = pgmoon.new(db_credentials)

  assert(pg:connect())
  result, err, partial, num_queries = pg:query(
    "SELECT * FROM " .. name .. "(" .. pg:escape_literal(arg) .. ");"
  )

  pg:keepalive()
  pg = nil

  if result ~= nil then
    result = cjson.encode(result[1][name])
  end

  return result, err, partial, num_queries
end

return db
