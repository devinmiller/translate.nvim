local log = require("translate.util.log")
local config = require("translate.config")

local M = {}

M._format_header = function(entry, formatted)
  local header = string.format("# %s", entry["word"])
  local padding = string.rep("=", #header)
  table.insert(formatted, padding)
  table.insert(formatted, header)
  table.insert(formatted, padding)
end

M._format_subheader = function(entry, formatted)
  local sub_header = string.format("**%s**", entry["pos"])
  -- TODO: ensure hyphen is just a plain string in jq
  if #entry["hyphenation"] > 0 then
    sub_header = sub_header .. " " .. entry["hyphenation"][1]
  end
  table.insert(formatted, sub_header)
end

M._format_forms = function(entry, formatted)
  if #entry["forms"] > 0 then
    table.insert(formatted, "")
    table.insert(formatted, "~~~")

    local longest_key = 0
    local longest_val = 0
    local forms = {}

    for _, value in ipairs(entry["forms"]) do
      if not value["source"] or value["source"] ~= "conjugation" then
        longest_key = math.max(longest_key, #value["form"])
        longest_val = math.max(longest_val, #value["tags"])
        forms[value["form"]] = value["tags"]
      end
    end

    for form, tags in pairs(forms) do
      local line = ("| %%-%ds | %%-%ds |")
          :format(longest_val, longest_key)
          :format(tags, form)
      table.insert(formatted, line)
    end

    table.insert(formatted, "~~~")
  end
end

M._format_definitions = function(entry, formatted)
  if #entry["senses"] > 0 then
    table.insert(formatted, "")
    for j, v in ipairs(entry["senses"]) do
      local definition = string.format("%i. ", j)
      -- get any tags for this definition
      if v["tags"] then
        definition = definition .. string.format("*%s*", table.concat(v["tags"], " ")) .. " "
      end
      -- get any synonyms for this definition
      if #v["synonyms"] > 0 then
        definition = definition .. string.format("(%s) ", table.concat(v["synonyms"], ", "))
      end
      -- build the definition for the word
      if #v["glosses"] > 0 then
        definition = definition .. table.concat(v["glosses"])
        table.insert(formatted, definition)
      end
    end
  end
end

--- Entries in the dictionary tend to be inconsistent and messy, but let's
--- make an effort to ensure consistent formatting
--- @param entries table: Entries to be formatted for displaying in buffer
M.format_entries = function(entries)
  local formatted = {}
  for i, entry in ipairs(entries) do
    -- just add the word to the first line
    M._format_header(entry, formatted)
    -- on the next line include the part of speech and hyphenated entry
    M._format_subheader(entry, formatted)
    -- if noun or adj add the feminine and masiculine forms
    M._format_forms(entry, formatted)
    -- finally, included the definitions buried under senses
    M._format_definitions(entry, formatted)

    if i < #entries then
      table.insert(formatted, "")
    end
  end
  return formatted
end

--- @param lines string[]: The lines of JSON strings to be parsed
M.parse_json = function(lines)
  local results = {}

  for _, line in ipairs(lines) do
    if line ~= "" and line ~= nil then
      local ok, decoded = pcall(vim.json.decode, line)
      if ok then
        table.insert(results, decoded)
      else
        log.error("dictionary.parse", "Invalid JSON on line: %s", line)
      end
    end
  end

  return results
end

--- Try to find the entries in the dictionary that provide the best definitions
--- TODO: Add a check for the "form_of" field that is occasionally present in entries
--- @param entries table: The entries that ripgrep found for the pattern
--- @param pattern string: The pattern that ripgrep for which ripgrep searched
M.find_matches = function(entries, pattern)
  local matches = {}
  local forms = {}
  for _, entry in ipairs(entries) do
    -- the most obvious, check for exact word match
    if entry["word"] == pattern then
      table.insert(matches, entry)

      for _, sense in ipairs(entry["senses"]) do
        for _, form in ipairs(sense["form_of"]) do
          if not vim.tbl_contains(forms, form) then
            table.insert(forms, form)
            local results = M.search_dict(form)
            for _, v in ipairs(results) do
              if v["word"] == form then
                table.insert(matches, v)
              end
            end
          end
        end
      end
    end
  end

  return vim.tbl_values(matches)
end

---@return table
M.search_dict = function(pattern)
  local jq = require("translate.util.jq")

  -- the command to run to search the dictionary file
  local rg_cmd = {
    -- command to call rg
    "rg", "-w", "--no-heading", "--color=never",
    -- pattern being search for
    string.format('"word": "%s"', pattern),
    -- file being searched in
    config.options.dict_file,
  }

  -- run ripgrip get to quickly search dictionary
  local rg_result = vim.system(rg_cmd, { text = true }):wait()

  -- the command to format the entries
  local jq_cmd = {
    "jq",
    "-c",
    jq._build_jq_body()
  }

  -- feed the ripgrep results to jq
  local jq_result = vim.system(jq_cmd, { text = true, stdin = rg_result.stdout }):wait()
  -- capture the out of jq and split by line breaks
  local entries = vim.split(jq_result.stdout, "\n")

  -- parse the lines and return entries
  return M.parse_json(entries)
end

--- @param pattern string: The pattern to search for in the dictionary
M.find_entries = function(pattern)
  -- validate parameters
  if pattern == nil or pattern == "" then
    log.warn("dict.find_entries", "No word provided")
    return {}
  end

  -- go search the dictionary
  local entries = M.search_dict(pattern)
  -- find the best match in the entries
  local matched = M.find_matches(entries, pattern)
  -- format entries and return
  return M.format_entries(matched)
end

return M
