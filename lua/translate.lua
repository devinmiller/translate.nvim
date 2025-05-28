local Translate = {}
local H = {}

Translate.setup = function(config)
	-- Export module
	_G.Translate = Translate

	-- Setup config
	config = H.setup_config(config)

	-- Apply config
	H.apply_config(config)

	-- Create default highlighting
	H.create_default_hl()
end

--- Module config
Translate.config = {
	-- Prints useful logs about what event are triggered, and reasons actions are executed.
	debug = false,
	-- Path to where the dictionary file is located
	dict_path = nil,
	-- Configuration options for the floating window that is created
	window = {
		width = 80,
		height = 10,
		border = "rounded",
		focusable = false,
		winblend = 0,
	},
	mappings = {
		scroll_down = "<C-N>",
		scroll_up = "<C-P>",
	},
}

Translate.open = function()
	local win_opts = H.get_config().window

	if H.is_window_open() then
		Translate.close()
	end

	-- Open buffer
	local buf_id = H.current.buf_id
	if buf_id == nil or not vim.api.nvim_buf_is_valid(buf_id) then
		buf_id = H.buffer_create()
		H.current.buf_id = buf_id
	end

	-- Load translation
	local translation = Translate.translate()
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, translation)

	-- Open window
	local win_id = vim.api.nvim_open_win(buf_id, false, H.normalize_window_options(win_opts))

	vim.wo[win_id].winblend = win_opts.winblend
	vim.wo[win_id].winhighlight = "NormalFloat:TranslateNormal,FloatBorder:TranslateBorder,FloatTitle:TranslateTitle"
	vim.wo[win_id].wrap = true
	H.current.win_id = win_id
end

---@return table: The parsed dictionary entries
Translate.translate = function()
	local pattern = vim.fn.expand("<cword>")

	-- validate parameters
	if pattern == nil or pattern == "" then
		return { "No word found at cursor" }
	end

	-- go search the dictionary
	local entries = Translate.search(pattern)

	-- find the best match in the entries
	local matches = {}
	for _, entry in ipairs(entries) do
		-- the most obvious, check for exact word match
		if entry["word"] == pattern then
			table.insert(matches, entry)
			-- if this word is a form of another word, let's find it
			for _, form in ipairs(entry["form_of"]) do
				local results = Translate.search(form)
				for _, v in ipairs(results) do
					if v["word"] == form then
						table.insert(matches, v)
					end
				end
			end
		end
	end
	local matched = vim.tbl_values(matches)

	-- format entries and return
	return H.format(matches)
end

---@param pattern string: The pattern being searched for
---@return table: The parsed dictionary entries
Translate.search = function(pattern)
	local config = H.get_config()

	-- the command to run to search the dictionary file
	local rg_cmd = {
		-- command to call rg
		"rg",
		"-w",
		"--no-heading",
		"--color=never",
		-- pattern being search for
		string.format('"word": "%s"', pattern),
		-- file being searched in
		vim.fn.expand(config.dict_path),
	}

	-- run ripgrip get to quickly search dictionary
	local rg_result = vim.system(rg_cmd, { text = true }):wait()

	-- the command to format the entries
	local jq_cmd = {
		"jq",
		"-c",
		H.build_jq_expression(),
	}

	-- feed the ripgrep results to jq
	local jq_result = vim.system(jq_cmd, { text = true, stdin = rg_result.stdout }):wait()
	-- capture the out of jq and split by line breaks
	local entries = vim.split(jq_result.stdout, "\n")

	-- parse the lines and return entries
	return H.parse_json(entries)
end

Translate.close = function()
	if H.is_valid_win(H.current.win_id) then
		vim.api.nvim_win_close(H.current.win_id, true)
	end
	H.current.win_id = nil
end

-- Helper data ================================================================
-- Module default config
H.default_config = vim.deepcopy(Translate.config)

H.current = {
	buf_id = nil,
	win_id = nil,
}

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
H.setup_config = function(config)
	-- Check that a config has been passed in
	H.check_type("config", config, "table", true)
	-- Extend default config with options passed in from setup
	config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})

	H.check_type("window", config.window, "table")

	return config
end

H.apply_config = function(config)
	Translate.config = config

	local map_scroll = function(lhs, direction)
		local rhs = function()
			return H.window_scroll(direction) and "" or lhs
		end
		H.map({ "n", "i" }, lhs, rhs, { expr = true, desc = "Scroll window " .. direction })
	end
	map_scroll(config.mappings.scroll_down, "down")
	map_scroll(config.mappings.scroll_up, "up")
end

H.get_config = function(config)
	return vim.tbl_deep_extend("force", Translate.config, vim.b.translate_config or {}, config or {})
end

H.create_default_hl = function()
	local hi = function(name, opts)
		opts.default = true
		vim.api.nvim_set_hl(0, name, opts)
	end

	hi("TranslateBorder", { link = "FloatBorder" })
	hi("TranslateNormal", { link = "NormalFloat" })
	hi("TranslateTitle", { link = "FloatTitle" })
end

-- Buffer ---------------------------------------------------------------------
H.buffer_create = function()
	local buf_id = vim.api.nvim_create_buf(false, true)
	H.set_buf_name(buf_id, "content")
	vim.bo[buf_id].filetype = "markdown"
	return buf_id
end

-- Window ---------------------------------------------------------------------

H.window_scroll = function(direction)
	if not (direction == "down" or direction == "up") then
		H.error('`direction` should be one of "up" or "down"')
	end

	local win_id = H.is_valid_win(H.current.win_id) and H.current.win_id or nil
	if win_id == nil then
		return false
	end

	-- Schedule execution as scrolling is not allowed in expression mappings
	local key = direction == "down" and "\6" or "\2"
	vim.schedule(function()
		if not H.is_valid_win(win_id) then
			return
		end
		vim.api.nvim_win_call(win_id, function()
			vim.cmd("noautocmd normal! " .. key)
		end)
	end)

	return true
end

H.normalize_window_options = function(win_opts)
	local opts = {
		relative = "cursor",
		row = 1,
		col = 1,
		width = win_opts.width,
		height = win_opts.height,
		style = "minimal",
		border = win_opts.border,
		focusable = win_opts.focusable,
	}

	return opts
end

H.is_window_open = function()
	local cur_win_id = H.current.win_id
	return cur_win_id ~= nil and vim.api.nvim_win_is_valid(cur_win_id)
end

-- Formatting -------------------------------------------------------------------------
--- Entries in the dictionary tend to be inconsistent and messy, but let's
--- make an effort to ensure consistent formatting
--- @param entries table: Entries to be formatted for displaying in buffer
H.format = function(entries)
	local formatted = {}
	for i, entry in ipairs(entries) do
		-- just add the word to the first line
		H.format_header(entry, formatted)
		-- on the next line include the part of speech and hyphenated entry
		H.format_subheader(entry, formatted)
		-- if noun or adj add the feminine and masculine forms
		H.format_forms(entry, formatted)
		-- finally, included the definitions buried under senses
		H.format_definitions(entry, formatted)

		if i < #entries then
			table.insert(formatted, "")
		end
	end
	return formatted
end

H.format_header = function(entry, formatted)
	local header = string.format("# %s", entry["word"])
	local padding = string.rep("=", #header)
	table.insert(formatted, padding)
	table.insert(formatted, header)
	table.insert(formatted, padding)
end

--- @param entry table: The entry from the dictionary
--- @param formatted table: The entry formatted for display
H.format_subheader = function(entry, formatted)
	local sub_header = string.format("**%s**", entry["pos"])
	-- TODO: ensure hyphen is just a plain string in jq
	if #entry["hyphenation"] > 0 then
		sub_header = sub_header .. " " .. entry["hyphenation"][1]
	end
	table.insert(formatted, sub_header)
end

--- @param entry table: The entry from the dictionary
--- @param formatted table: The entry formatted for display
H.format_forms = function(entry, formatted)
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
			local line = ("| %%-%ds | %%-%ds |"):format(longest_val, longest_key):format(tags, form)
			table.insert(formatted, line)
		end

		table.insert(formatted, "~~~")
	end
end

--- @param entry table: The entry from the dictionary
--- @param formatted table: The entry formatted for display
H.format_definitions = function(entry, formatted)
	if #entry["senses"] > 0 then
		table.insert(formatted, "")
		for j, v in ipairs(entry["senses"]) do
			local definition = string.format("%i. ", j)
			-- get any tags for this definition
			if #v["tags"] > 0 then
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

H.build_jq_expression = function()
	local jq_forms_parts = {
		form = "form: .form",
		source = "source: (.source)",
		tags = 'tags: (.tags // [] | join(" "))',
	}

	local jq_senses_parts = {
		glosses = "glosses: (.glosses // [] | .)",
		form_of = "form_of: (.form_of // [] | map(.word))",
		tags = "tags: (.tags // [])",
		synonyms = "synonyms: (.synonyms // [] | map(.word))",
		alt_of = "alt_of: (.alt_of // [] | map(.word))",
		related = "related: (.related // [] | map(.word))",
		examples = "examples: (.examples // [])",
	}

	local jq_parts = {
		hyphenation = "hyphenation: (.hyphenation // [])",
		related = "related: (.related // [] | map(.word))",
		forms = string.format(
			"forms: (.forms // [] | map({%s, %s, %s}))",
			jq_forms_parts["form"],
			jq_forms_parts["source"],
			jq_forms_parts["tags"]
		),
		senses = string.format(
			"senses: [.senses[] | {%s, %s, %s, %s, %s, %s, %s}]",
			jq_senses_parts["glosses"],
			jq_senses_parts["form_of"],
			jq_senses_parts["tags"],
			jq_senses_parts["synonyms"],
			jq_senses_parts["alt_of"],
			jq_senses_parts["related"],
			jq_senses_parts["examples"]
		),
		-- flattening and deduplicating helps considerably in the code
		form_of = "form_of: ([.senses[] | .form_of[]? | .word] | unique)",
	}

	return string.format(
		"{word: .word, pos: .pos, %s, %s, %s, %s, %s}",
		jq_parts["hyphenation"],
		jq_parts["related"],
		jq_parts["forms"],
		jq_parts["senses"],
		jq_parts["form_of"]
	)
end

-- Utilities ------------------------------------------------------------------
H.error = function(msg)
	error("(translate) " .. msg, 0)
end

H.check_type = function(name, val, ref, allow_nil)
	if type(val) == ref or (ref == "callable" and vim.is_callable(val)) or (allow_nil and val == nil) then
		return
	end
	H.error(string.format("`%s` should be %s, not %s", name, ref, type(val)))
end

H.map = function(mode, lhs, rhs, opts)
	if lhs == "" then
		return
	end
	opts = vim.tbl_deep_extend("force", { silent = true }, opts or {})
	vim.keymap.set(mode, lhs, rhs, opts)
end

H.set_buf_name = function(buf_id, name)
	vim.api.nvim_buf_set_name(buf_id, "translate://" .. buf_id .. "/" .. name)
end

H.is_valid_buf = function(buf_id)
	return type(buf_id) == "number" and vim.api.nvim_buf_is_valid(buf_id)
end

H.is_valid_win = function(win_id)
	return type(win_id) == "number" and vim.api.nvim_win_is_valid(win_id)
end

--- @param lines string[]: The lines of JSON strings to be parsed
H.parse_json = function(lines)
	local results = {}

	for _, line in ipairs(lines) do
		if line ~= "" and line ~= nil then
			local ok, decoded = pcall(vim.json.decode, line)
			if ok then
				table.insert(results, decoded)
			else
				H.error("Invalid JSON")
			end
		end
	end

	return results
end

return Translate
