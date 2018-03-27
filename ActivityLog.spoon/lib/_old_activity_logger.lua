local Universe = ... -- Expect our globals to be passed in while loading this file.
local module = {}
local ACTIVITY_LOG_PATH = Universe.spoonPath.."db/activities.log"
local LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %X'

local FLUSH_THRESHOLD = 10
local CURRENT_BUFFER_SIZE = 0
local LREAD_HANDLE = nil
local LWRITE_HANDLE = nil

-- Ensure log file exists
io.open(ACTIVITY_LOG_PATH, 'a+'):close()

function module:saveLogs()
  if LWRITE_HANDLE then
    if io.type(LWRITE_HANDLE) == 'file' then
      LWRITE_HANDLE:close()
      CURRENT_BUFFER_SIZE = 0
    end
    return true
  else
    return false
  end
end

function module:logActivity(activity)
  if LWRITE_HANDLE == nil or io.type(LWRITE_HANDLE) == 'closed file' then
    LWRITE_HANDLE = assert(io.open(ACTIVITY_LOG_PATH, 'a+'))
  end

  local newLog = string.format("%s: %s\n", os.date(LOG_TIMESTAMP_FORMAT), activity)
  print(newLog)
  LWRITE_HANDLE:write(newLog)

  CURRENT_BUFFER_SIZE = CURRENT_BUFFER_SIZE+1
  if CURRENT_BUFFER_SIZE >= FLUSH_THRESHOLD then
    self.saveLogs()
  end

  return newLog
end

function module:logs()
  if LREAD_HANDLE == nil or io.type(LREAD_HANDLE) == 'closed file' then
    LREAD_HANDLE = assert(io.open(ACTIVITY_LOG_PATH, 'r'))
  end

  local logs = {}
  for log in LREAD_HANDLE:lines() do
    table.insert(logs, log)
  end

  LREAD_HANDLE:close()

  return logs
end

---
return module
