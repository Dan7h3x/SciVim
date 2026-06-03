; queries/markdown/highlights.scm
; Treesitter highlight queries for ZK wikilinks in markdown.
; Place this file at: queries/markdown/zk_highlights.scm
; These extend the standard markdown grammar.

; [[wikilink]]
; Note: standard markdown TS grammar does not parse wikilinks natively,
; so we match via inline patterns. Parsers like markdown-inline + custom
; injections can use these.

; Match [[...]] as a special inline element
; This works with nvim-treesitter injected grammar approach.
((inline) @zk.wikilink
  (#match? @zk.wikilink "\\[\\["))
