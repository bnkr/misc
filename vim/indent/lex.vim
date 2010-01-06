" Vim indent file
" Language:    Lex
" Maintainer:  James Webber <bunkerprivate@googlemail.com>
" Last Change: Jan 2010

if exists("b:did_indent")
   finish
endif

setlocal cindent

let b:did_indent = 1
let b:undo_indent = "setl cin<"
