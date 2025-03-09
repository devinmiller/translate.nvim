# Product Context

## Purpose
translate.nvim is a Neovim plugin designed to provide in-editor translation capabilities for words and phrases. It leverages machine-readable dictionary data from Wiktionary (specifically from kaikki.org) to offer translations directly within the Neovim environment.

## Problems Solved
1. **Seamless Translation**: Allows users to translate words without leaving their editor, maintaining focus and workflow
2. **Context-Aware Translations**: Provides detailed linguistic information including part of speech, forms, and multiple definitions
3. **Visual Integration**: Displays translations in a floating window that appears near the cursor, making it non-disruptive to the editing experience

## User Experience Goals
1. **Minimal Disruption**: The translation window appears near the cursor and can be easily dismissed
2. **Rich Information**: Provides comprehensive linguistic details including:
   - Word forms (conjugations, declensions)
   - Multiple definitions with tags for context
   - Synonyms when available
3. **Simple Interaction**: Works with both visual selections and cursor position (current word)
4. **Keyboard Navigation**: Allows scrolling through translation content with keyboard shortcuts

## Target Users
- Neovim users who:
  - Work with multilingual content
  - Are learning new languages
  - Need occasional translation assistance while writing or reading
  - Prefer keyboard-driven workflows and in-editor tools over external applications

## Usage Scenarios
1. **Language Learning**: A user writing in a foreign language can quickly check word meanings and forms
2. **Content Translation**: A translator working on a document can verify word meanings without context switching
3. **Reading Comprehension**: A user reading foreign text can quickly look up unfamiliar words
4. **Writing Assistance**: A writer can find the right word by checking translations and synonyms
