local pgmoon = require("pgmoon")
local db_credentials = require("db_credentials")

local db = {}

function db.call(name, arg)
  local pg = pgmoon.new(db_credentials)

  assert(pg:connect())
  pg:query("CALL " .. name .. "(" .. pg:escape_literal(arg) .. ");")

  pg:keepalive()
  pg = nil
end

return db
