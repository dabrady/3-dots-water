local Universe = ... -- Expect our globals to be passed in while loading this file.
local sqlite = require('hs.sqlite3')

local uuid = (function()
  local uuidGenerator = require('uuid')
  uuidGenerator.randomseed(math.random(0,2^32))
  uuidGeneratorSeed = uuidGenerator()
  return function()
    return uuidGenerator(uuidGeneratorSeed)
  end
)()

local module = {}
local ACTIVITY_DB_PATH = Universe.spoonPath.."/db/activities.db"
module.db_path = ACTIVITY_DB_PATH

function module:createActivitiesTable()
  local db,code,err = sqlite.open(ACTIVITY_DB_PATH, sqlite.OPEN_READWRITE + sqlite.OPEN_CREATE)
  assert(db, err)

  local res = db:exec [[
    CREATE TABLE IF NOT EXISTS activities (
      id TEXT NOT NULL PRIMARY KEY,
      event_name TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) WITHOUT ROWID;

    CREATE UNIQUE INDEX IF NOT EXISTS idx_primary_key ON activities(id);
    CREATE INDEX IF NOT EXISTS idx_activities_event_name ON activities(event_name);
  ]]
  db:close()
  return res
end

function module:clearActivities()
  local db,_,err = sqlite.open(ACTIVITY_DB_PATH)
  assert(db, err)
  local res = db:exec[[ DELETE FROM activities; ]]
  db:close()
  return res
end

function module:logActivity(event_name)
  local db,_,err = sqlite.open(ACTIVITY_DB_PATH)
  assert(db, err)

  local statement,err = db:prepare [[
    INSERT INTO activities (id, event_name)
    VALUES (:id, :event_name)
  ]]
  if not statement then return nil, db:error_message() end

  statement:bind_names({
    id = uuid(),
    event_name = event_name
  })
  local res = statement:step()
  if res ~= sqlite.DONE then
    err = db:error_message()
  end
  db:close()
  return res, err
end

function module:logs()
  local db,_,err = sqlite.open(ACTIVITY_DB_PATH, sqlite.OPEN_READONLY)
  assert(db, err)

  local logs = {}
  for log in db:nrows('SELECT * from activities') do
    table.insert(logs, log)
  end
  db:close()

  return logs
end

---
return module
