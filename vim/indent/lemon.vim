" Vim indent file
" Language:    Lemon
" Maintainer:  James Webber <bunkerprivate@googlemail.com>
" Last Change: Jan 2010

if exists("b:did_indent")
   finish
endif

" This pretty much sorts us out.
setlocal cindent

let b:did_indent = 1
let b:undo_indent = "setl cin<"
