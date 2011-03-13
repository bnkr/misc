" Vim indent file.
"
" Language:     Ragel (ft=ragel)
" Author:       James Webber <bunkerprivate@gmail.com>
" Licence:      2-clause BSD.

if exists("b:did_indent")
   finish
endif

" This pretty much sorts us out.
setlocal cindent

let b:did_indent = 1
let b:undo_indent = "setl cin<"
