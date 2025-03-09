# Technical Context

## Technologies Used

### Core Technologies
- **Lua**: Primary programming language used for the plugin
- **Neovim API**: Used for editor integration, window management, and user interaction
- **Ripgrep**: External tool used for efficient text searching in the dictionary file
- **JQ**: External tool used for JSON processing and transformation

### Data Format
- **JSONL**: The dictionary data is stored in JSONL (JSON Lines) format
- **Markdown**: Used for formatting the translation output in the floating window

## Development Setup

### Requirements
- Neovim (with Lua support)
- Ripgrep installed on the system
- JQ installed on the system
- Dictionary data file from kaikki.org

### Dictionary Data
- Source: https://kaikki.org/dictionary/rawdata.html
- Format: JSONL (JSON Lines)
- Default location: `vim.fn.stdpath("data")/kaikki.org-dictionary-{language}.jsonl`

## Technical Constraints

### External Dependencies
- Requires external tools (ripgrep, jq) to be installed on the user's system
- Depends on dictionary data being available in the correct format and location

### Performance Considerations
- Dictionary files can be large (hundreds of MB)
- Uses ripgrep for efficient searching instead of loading the entire file
- JQ processes only the matched entries, not the entire dictionary

### Neovim Version Requirements
- Uses `vim.system()` which requires a recent version of Neovim
- Uses floating window API features

## Plugin Integration

### Installation
Can be installed using any Neovim plugin manager:

```lua
-- Using packer.nvim
use {
  'user/translate.nvim',
  config = function()
    require('translate').setup({
      -- configuration options
    })
  end
}
```

### Configuration Options
```lua
require('translate').setup({
  -- Prints useful logs about what events are triggered
  debug = false,
  -- Path to where the dictionary file is located
  dict_path = vim.fn.stdpath("data"),
  -- Language to translate
  language = "Italian",
  -- Configuration options for the floating window
  window = {
    width = 80,
    height = 10,
    border = "rounded",
    winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
  }
})
```

### User Commands
- `TranslateSelection`: Translates the current word or visual selection

### Default Keymaps
- `<leader>tw`: Close the translation window
- `<C-P>`: Scroll up in the translation window
- `<C-N>`: Scroll down in the translation window

## Technical Debt and Limitations

### Current Limitations
- Only supports one language at a time
- Requires dictionary file to be downloaded separately
- No fuzzy matching or spell correction
- Limited to the content available in the Wiktionary data

### Potential Improvements
- Support for multiple languages simultaneously
- Automatic dictionary file downloading
- Improved search capabilities (fuzzy matching, spell correction)
- Integration with online translation APIs as a fallback
