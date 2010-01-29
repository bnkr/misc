" Vim filetype plugin file
"
" Based on c.vim by Bram.
"
" Language:    Lex
" Maintainer:  James Webber
" Last Change: December 2009

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let b:undo_ftplugin = "setl fo< com< ofu< "

" Set 'formatoptions' to break comment lines but not other lines,
" and insert the comment leader when hitting <CR> or using "o".
setlocal fo-=t fo+=croql

" Nothing special -- just make sure lists can be formatted and that only C-ish
" comments are available.
setlocal comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,://

" When the matchit plugin is loaded, this makes the % command skip parens and
" braces in comments.
let b:match_words = &matchpairs
let b:match_skip = 's:comment\|string\|character'
