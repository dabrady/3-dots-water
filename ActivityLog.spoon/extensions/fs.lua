local fs_ext = {}
require 'extensions/string'

-- Returns a list of directories in the given path.
function fs_ext.dirs(path)
  local _,directoryContents = hs.fs.dir(path)
  local directories = {}
  repeat
    local filename = directoryContents:next()
    if (
      filename and
      filename:match("^%.") == nil and -- Exclude dotfiles
      hs.fs.attributes(path..filename, 'mode') == 'directory'
    ) then

      table.insert(directories, filename)
    end
  until filename == nil
  directoryContents:close()

  return directories
end

-- Load each .LUA file in a given directory, with any arguments given.
function fs_ext.loadAllScripts(rootDir, ...)
  -- Make sure our root ends with a directory marker.
  rootDir = rootDir:endsWith('/') and rootDir or rootDir..'/'

  local loadedScripts = {}
  local _,scripts = hs.fs.dir(rootDir)
  repeat
    local filename = scripts:next()
    if filename and filename ~= '.' and filename ~= '..' then
      print('\t\tloading script: '..filename)
      -- Load the script, passing the given arguments as parameters to the Lua chunk.
      -- Using `assert(loadfile(...))` instead of `require` to be compatible with Spoons.
      local script = assert(loadfile(rootDir..filename))(...)
      local basename = filename:match("^(.+)%.") -- Matches everything up to the first '.'
      loadedScripts[basename] = script
    end
  until filename == nil

  return loadedScripts
end

------

return fs_ext
