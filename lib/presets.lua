--[[
  dtMediaWiki preset support
-- dtMediaWiki metadata preset handling
]]

local dt = require "darktable"

local M = {}

-----------------------------------------------------------------------
-- Configuration
-----------------------------------------------------------------------

local path_sep =
  package.config:sub(1, 1)

local preset_dir =
  dt.configuration.config_dir
  .. path_sep
  .. "dtMediaWiki"

local preset_file =
  preset_dir
  .. path_sep
  .. "presets.lua"

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function ensure_preset_dir()

  local test_file =
    preset_dir
    .. path_sep
    .. ".dtmediawiki-write-test"

  local file =
    io.open(
      test_file,
      "w"
    )

  if file then
    file:close()
    os.remove(test_file)
    return true
  end

  local command

  if path_sep == "\\" then

    command =
      'mkdir "'
      .. preset_dir
      .. '" >NUL 2>&1'

  else

    command =
      'mkdir -p "'
      .. preset_dir
      .. '" >/dev/null 2>&1'
  end

  os.execute(command)

  file =
    io.open(
      test_file,
      "w"
    )

  if file then
    file:close()
    os.remove(test_file)
    return true
  end

  return false
end

local function serialize_string(value)

  return string.format(
    "%q",
    tostring(value or "")
  )
end


local function write_field(
  file,
  name,
  value,
  indent
)

  if value == nil then
    return
  end

  indent = indent or ""

  file:write(
    indent,
    name,
    " = ",
    serialize_string(value),
    ",\n"
  )
end

-----------------------------------------------------------------------
-- Load presets
-----------------------------------------------------------------------

function M.load()

  local file =
    io.open(
      preset_file,
      "r"
    )

  if not file then
    return {}
  end

  file:close()

  local ok, result =
    pcall(
      dofile,
      preset_file
    )

  if not ok then

    dt.print_log(
      "dtMediaWiki: unable to load presets: "
      .. tostring(result)
    )

    return {}
  end

  if type(result) ~= "table" then

    dt.print_log(
      "dtMediaWiki: invalid preset file"
    )

    return {}
  end

  return result
end

-----------------------------------------------------------------------
-- Save presets
-----------------------------------------------------------------------

function M.save(presets)

  if type(presets) ~= "table" then
    return false, "presets must be a table"
  end

  if not ensure_preset_dir() then
    return false,
      "unable to create preset directory: "
      .. preset_dir
  end

  local file, err =
    io.open(
      preset_file,
      "w"
    )

  if not file then
    return false, err
  end

  file:write(
    "-- dtMediaWiki presets\n",
    "-- generated automatically\n\n",
    "return {\n"
  )

  for _, preset in ipairs(presets) do

    file:write("  {\n")

    write_field(
      file,
      "name",
      preset.name,
      "    "
    )

    ---------------------------------------------------------------
    -- Image metadata
    ---------------------------------------------------------------

    if preset.image then

      file:write(
        "    image = {\n"
      )

      local keys = {}

      for key, value in pairs(
        preset.image
      ) do

        if value ~= nil
            and value ~= "" then

          table.insert(
            keys,
            key
          )
        end
      end

      table.sort(keys)

      for _, key in ipairs(keys) do

        write_field(
          file,
          key,
          preset.image[key],
          "      "
        )
      end

      file:write(
        "    },\n"
      )
    end

    ---------------------------------------------------------------
    -- Export metadata
    ---------------------------------------------------------------

    file:write(
      "  },\n"
    )
  end

  file:write(
    "}\n"
  )

  file:close()

  return true
end

-----------------------------------------------------------------------
-- Find preset by name
-----------------------------------------------------------------------

function M.find(
  presets,
  name
)

  for _, preset in ipairs(
    presets or {}
  ) do

    if preset.name == name then
      return preset
    end
  end

  return nil
end

-----------------------------------------------------------------------
-- Public information
-----------------------------------------------------------------------

function M.get_file()

  return preset_file
end

return M
