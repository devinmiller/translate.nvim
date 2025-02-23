local M = {}

-- this is ugly and I deserve to feel bad
M._build_jq_body = function()
  local jq_forms_parts = {
    form = "form: .form",
    source = "source: (.source)",
    tags = 'tags: (.tags // [] | join(" "))'
  }

  local jq_senses_parts = {
    glosses = "glosses: (.glosses // [] | .)",
    form_of = "form_of: (.form_of // [] | map(.word))",
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
      jq_forms_parts["tags"]),
    senses = string.format(
      "senses: [.senses[] | {%s, %s, %s, %s, %s, %s}]",
      jq_senses_parts["glosses"],
      jq_senses_parts["form_of"],
      jq_senses_parts["synonyms"],
      jq_senses_parts["alt_of"],
      jq_senses_parts["related"],
      jq_senses_parts["examples"]
    ),
    -- flattening and deduplicating helps considerable in the code
    form_of = "form_of: ([.senses[] | .form_of[]? | .word] | unique)"
  }

  return string.format(
    "{word: .word, pos: .pos, %s, %s, %s, %s, %s}",
    jq_parts["hyphenation"],
    jq_parts["related"],
    jq_parts["forms"],
    jq_parts["senses"],
    jq_parts["form_of"])
end

return M
