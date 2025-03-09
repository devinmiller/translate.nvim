# Project Brief

## Overview
translate.nvim is a Neovim plugin that provides in-editor translation capabilities. It allows users to translate words and phrases without leaving their editor, maintaining focus and workflow.

## Core Functionality
- Translate words under cursor or visual selections
- Display translations in a floating window near the cursor
- Format translations with rich Markdown for better readability
- Provide comprehensive linguistic information (definitions, forms, synonyms)

## Data Source
The plugin uses machine-readable dictionary data in JSONL format extracted from Wiktionary. This data is sourced from https://kaikki.org/dictionary/rawdata.html.

## Key Features
- Non-disruptive translation experience with floating windows
- Detailed linguistic information including part of speech, forms, and definitions
- Simple keyboard-driven interaction
- Configurable appearance and behavior

## Technical Approach
- Uses external tools (ripgrep, jq) for efficient dictionary searching and processing
- Formats entries as Markdown for better readability
- Provides a modular architecture with clear separation of concerns
- Offers flexible configuration options

## Target Users
Neovim users who work with multilingual content, are learning new languages, or need occasional translation assistance while writing or reading.
