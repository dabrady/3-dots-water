local sqlite3 = hs.sqlite3

-- Prepare a statement for multiple runs with potentially different arguments.
function sqlite3.runner(db, statement)
  local sm, err = db:prepare(statement)
  if not sm then return nil, err end

  return function(params, format)
    if params then
      if not format then format = 'names' end
      if format == 'names' then
        sm:bind_names(params)
      elseif format == 'values' then
        sm:bind_values(table.unpack(params))
      end

      local resCode = sm:step()
      local err = nil
      sm:reset()
      if resCode ~= sqlite3.ROW or resCode ~= sqlite3.DONE then
        err = db:error_message()
      end
      return resCode, err
    else
      sm:finalize()
    end
  end
end

-- Prepare and execute the given statement.
-- The 'params' argument is an optional table of values to plug into the statement.
-- The 'format' argument is an optional string, one of ['values'|'names'], indicating the type of bindings used
-- in the statement string.
function sqlite3.run(db, statement, params, format)
  local runner = sqlite3.runner(db, statement)
  local resCode, err = runner(params,format)
  runner() -- Finalize the internal statement
  return resCode, err
end

-- Prepare a query for multiple runs with potentially different arguments.
function sqlite3.reader(db, statement)
  local sm, err = db:prepare(statement)
  if not sm then return nil, err end

  return function(params, format)
    if params then
      if not format then format = 'names' end
      if format == 'names' then
        sm:bind_names(params)
      elseif format == 'values' then
        sm:bind_values(table.unpack(params))
      end

      local resCode = sm:step()
      local err = nil
      local data = nil
      sm:reset()
      if resCode ~= sqlite3.ROW or resCode ~= sqlite3.DONE then
        err = db:error_message()
      else
        data = sm:get_named_values()
      end
      return data, resCode, err
    else
      sm:finalize()
    end
  end
end

-- Prepare and execute the given statement, returning only the first result row as a table.
-- Don't use this if your query returns multiple rows.
-- The 'params' argument is an optional table of values to plug into the statement.
-- The 'format' argument is an optional string, one of ['values'|'names'], indicating the type of bindings used
-- in the statement string.
function sqlite3.read(db, statement, params, format)
  local reader = sqlite3.reader(db, statement)
  local data, resCode, err = reader(params, format)
  reader() -- Finalize the internal statement
  return data, resCode, err
end
