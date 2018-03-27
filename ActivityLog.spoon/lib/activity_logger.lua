local Universe = ... -- Expect our globals to be passed in while loading this file.
local sqlite = require('hs.sqlite3')
local uuid = require('uuid')
local module = {}
local ACTIVITY_DB_PATH = Universe.spoonPath.."db/activities.db"
local LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %X'

function module:createActivitiesTable()
  local db = assert(sqlite.open(ACTIVITY_DB_PATH))
  db:exec [[
    CREATE TABLE activities (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      t TIMESTAMP
      DEFAULT CURRENT_TIMESTAMP
    );
  ]]
end

function module:saveLogs()

end

function module:logActivity(activity)

  local newLog = string.format("%s: %s\n", os.date(LOG_TIMESTAMP_FORMAT), activity)

  return newLog
end

function module:logs()
  local db = assert(sqlite.open(ACTIVITY_DB_PATH, sqlite.OPEN_READONLY))

  local logs = {}
  for log in db:nrows('SELECT * from activities') do
    table.insert(logs, log)
  end
  db:closes()

  return logs
end

---
return module
