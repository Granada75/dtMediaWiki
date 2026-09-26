--[[
  dtMediaWiki Commons category search
  -- search Wikimedia Commons categories and add them to the
     selected images
]]

local dt = require "darktable"

local i18n =
  require "contrib/dtMediaWiki/lib/i18n"

local _ =
  i18n.translate

local placeholders =
  require "contrib/dtMediaWiki/lib/placeholders"

local MediaWikiApi =
  require "contrib/dtMediaWiki/lib/mediawikiapi"

local MetadataUI =
  require "contrib/dtMediaWiki/lib/metadata_ui"

local M = {}

-- darktable has no list widget, so results are shown in a fixed
-- pool of buttons which are relabeled and shown/hidden per search.
local MAX_RESULTS = 15

-- Category names of the currently shown result buttons.
local results = {}

-----------------------------------------------------------------------
-- Widgets
-----------------------------------------------------------------------

local search_entry =
  dt.new_widget("entry") {
    text = "",
    placeholder = _("Search Commons categories"),
    tooltip = _("Search terms, eg: cemetery innsbruck")
  }

local status =
  dt.new_widget("label") {
    label = ""
  }

local result_box =
  dt.new_widget("box") {
    orientation = "vertical"
  }

-----------------------------------------------------------------------
-- Add category to selected images
-----------------------------------------------------------------------

local function add_category(category)

  local images =
    dt.gui.selection() or {}

  if #images == 0 then
    dt.print(_("No image selected"))
    return
  end

  -- Flush pending edits of the metadata editor first, otherwise
  -- they would be lost, or would overwrite the new category on the
  -- next selection change.
  MetadataUI.save()

  local count = 0

  for _, image in ipairs(images) do

    local categories =
      placeholders.get_categories(image)

    local present = false

    for _, existing in ipairs(categories) do
      if existing == category then
        present = true
        break
      end
    end

    if not present then

      table.insert(categories, category)

      placeholders.set_categories(
        image,
        categories
      )

      count = count + 1
    end
  end

  MetadataUI.refresh()

  dt.print(
    string.format(
      _("Added [[Category:%s]] to %d image(s)"),
      category,
      count
    )
  )
end

-----------------------------------------------------------------------
-- Result buttons
-----------------------------------------------------------------------

local result_buttons = {}

for i = 1, MAX_RESULTS do

  local button =
    dt.new_widget("button") {
      label = "",
      visible = false,

      clicked_callback = function()
        if results[i] then
          add_category(results[i])
        end
      end
    }

  result_buttons[i] = button
  result_box[#result_box + 1] = button
end

local function show_results(categories)

  results = categories

  for i, button in ipairs(result_buttons) do

    local category = categories[i]

    if category then
      button.label = category
      button.tooltip = string.format(
        _("Add [[Category:%s]] to the selected images"),
        category
      )
      button.visible = true
    else
      button.label = ""
      button.visible = false
    end
  end
end

-----------------------------------------------------------------------
-- Search
-----------------------------------------------------------------------

local function search()

  local term =
    tostring(search_entry.text or "")
      :gsub("^%s+", "")
      :gsub("%s+$", "")

  if term == "" then
    return
  end

  status.label = _("Searching…")

  local ok, categories =
    pcall(
      MediaWikiApi.searchCategories,
      term,
      MAX_RESULTS
    )

  if not ok then
    show_results({})
    status.label = _("Search failed")
    dt.print(tostring(categories))
    return
  end

  categories = categories or {}

  show_results(categories)

  if #categories == 0 then
    status.label = _("No categories found")
  else
    status.label = _("Click a category to add it to the selected images")
  end
end

local search_button =
  dt.new_widget("button") {
    label = _("Search"),
    clicked_callback = search
  }

local widget =
  dt.new_widget("box") {
    orientation = "vertical",

    dt.new_widget("box") {
      orientation = "horizontal",
      search_entry,
      search_button
    },

    status,
    result_box
  }

-----------------------------------------------------------------------
-- Register module
-----------------------------------------------------------------------

dt.register_lib(
  "dtmediawiki_category_search",
  _("Wikimedia Commons category search"),
  true,   -- expandable
  false,  -- resettable

  {
    [dt.gui.views.lighttable] = {
      "DT_UI_CONTAINER_PANEL_RIGHT_CENTER",
      99
    }
  },

  widget,

  function()
  end,

  function()
  end
)

M.widget = widget

return M
