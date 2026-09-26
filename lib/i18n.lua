local dt = require "darktable"

local M = {}

local DOMAIN = "dtMediaWiki"

dt.gettext.bindtextdomain(
  DOMAIN,
  dt.configuration.config_dir .. "/lua/contrib/dtMediaWiki/locale/"
)

function M.translate(msgid)

  return dt.gettext.dgettext(
    DOMAIN,
    msgid
  )
end

return M
