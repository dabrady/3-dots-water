local ActivityLog = {
  name = 'ActivityLog',
  version = '0.0.1',
  author = 'Daniel Brady <daniel.13rady@gmail.com>',
  license = 'https://opensource.org/licenses/MIT',

  -- Absolute path to root of spoon
  spoonPath = (function()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
  end)()
}

local function withSpoonInPath(fn)
  -- Temporarily modify loadpath
  local oldPath = package.path
  local oldCPath = package.cpath
  package.path = string.format('%s?.lua;%s', ActivityLog.spoonPath, oldPath)
  package.cpath = string.format('%s?.so;%s', ActivityLog.spoonPath, oldCPath)

  fn()

  -- Reset loadpath
  package.path = oldPath
  package.cpath = oldCPath
end

local watchers =  {}
ActivityLog.logger = assert(loadfile(ActivityLog.spoonPath..'lib/activity_logger.lua'))(ActivityLog)
function ActivityLog:init()
  withSpoonInPath(function()
    local fs = dofile(ActivityLog.spoonPath..'extensions/fs.lua')
    watchers = fs.loadAllScripts(ActivityLog.spoonPath..'watchers', self.logger)
  end)

  return self
end

function ActivityLog:start()
  for name,watcher in pairs(watchers) do
    print("Starting watcher: "..name)
    watcher:start()
  end
end

function ActivityLog:stop()
  for name,watcher in pairs(watchers) do
    print("Stopping watcher: "..name)
    watcher:stop()
  end
end

function ActivityLog:bindHotkeys(mapping)
  local spec = {}
  hs.spoons.bindHotkeysToSpec(spec, mapping)
end

----

return ActivityLog
