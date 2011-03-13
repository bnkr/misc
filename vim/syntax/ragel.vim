" Vim syntax file
"
" Language: Ragel
" Author: James Webber
" Copyright: Copyright (C) James Webber 2011.  2-clause BSD License
"
" Highlights regel and whatever sub-language is being used by using a
" sub-syntax.
"
" TODO:
"   There is only a basic attempt to detect which langauge is running.  Needs
"   patching.

if exists("b:current_syntax")
  finish
endif

" Load a sub-syntax into the rlSubLang group.
fun! RagelLoadLangSyntax(language_file)
  " Otherwise the file will not define anything.
  if exists("b:current_syntax")
    unlet b:current_syntax
  end

  " Look for a file in ~/.vim first.  Docs imply you don't need to do this, so
  " maybe I've got it wrong.
  let s:relative_file = expand("<sfile>:p:h" . a:language_file)

  if filereadable(s:relative_file)
    exec 'syn include @rlSubLang ' . s:relative_file
  else
    exec 'syn include @rlSubLang ' . "$VIMRUNTIME/syntax/" . a:language_file
  end
endfun

""""""""""""""
" Sub-Syntax "
""""""""""""""

" TODO:
"   This needs to run a proper filetype detection with the .rl extension removed
"   somehow.

let b:rl_file = bufname("%")
if b:rl_file =~ "\.cpp\.[^.]\+$"
  call RagelLoadLangSyntax('cpp.vim')
else
  call RagelLoadLangSyntax('cpp.vim')
end
unlet b:rl_file

" Override whatever's set by cpp.vim.
syn sync fromstart

" This seems to be the only way to get it so that the ragel highlighting doesn't
" bleed into the C highlighting -- the 'contained' specified syntax ends up
" being macthed globally..  My guess is that the C or C++ highlighting uses
" @contained somewhere and that traps all my contained matches.
syn region rlDocument start="\%^" end="\%$" contains=rlMachine,rlWriteLine,@rlSubLang

"""""""""""""""
" Global Bits "
"""""""""""""""

syn match rlWriteLine "^\s*%%\s*write.*$" contains=rlWriteWhatOp,rlWritePercents,rlWriteOp contained

syn match rlWritePercents "%%" contained
syn keyword rlWriteOp write contained
syn keyword rlWriteWhatOp data nofinal exec init contained

"""""""""""""""""""""""""""""""""""""""
" Delimited machine, i.e %%{ ... }%%" "
"""""""""""""""""""""""""""""""""""""""

" The main bracket delimted region.
syn region rlMachine matchgroup=rlMachineDelim start="%%{" end="}%%" keepend contains=@rlItems contained

" Everything inside the machine.
syn cluster rlItems contains=rlComment,rlKeyword,rlCode,rlSString,rlCharClass,rlDString,rlBuiltIn,rlAction,rlSlashRegex

""""""""""""""""
" Machine body "
""""""""""""""""

syn match rlComment "#.*$" contained contains=rlTodo,@Spell
syn keyword rlKeyword machine include action alphatype getkey include contained
syn match rlSString /'[^']*'/ contained
syn match rlDString /"[^"]*"/ contained
" TODO:
"   These could be better wrt special characters and so on.
syn match rlCharClass /\[[^\]]*\]/ contained
syn match rlSlashRegex "/[^/]\+/[i]\?" contained

syn keyword rlBuiltin
      \ any ascii extend digit alnum lower upper xdigit cntrl graph print
      \ punct space zlen empty

" Note that this first one must be up here so the more verbose versions have a
" higher priority.
syn match rlAction /\([><$%@]\|<>\)/ contained
syn match rlAction /\([><$%@]\|<>\)\(to\|[~]\)/ contained
syn match rlAction /\([><$%@]\|<>\)\(from\|[*]\)/ contained
syn match rlAction /\([><$%@]\|<>\)\(eof\|[/]\)/ contained
syn match rlAction /\([><$%@]\|<>\)\(err\|[!]\)/ contained
syn match rlAction /\([><$%@]\|<>\)\(lerr\|[\^]\)/ contained
syn match rlAction /\([><$%@]\|<>\)\(to\|[~]\)/ contained
syn match rlAction /\([><$%@]\|<>\)\(to\|[~]\)/ contained

"""""""""""""""""
" Action Blocks "
"""""""""""""""""

syn region rlCode start="{" end="}" contained keepend contains=@rlSubLang,rlCodeOp,rlCodeVar
syntax keyword rlCodeVar fpc fc fcurs fbuf fblen ftargs fstack contained
syntax keyword rlCodeOp fhold fgoto fcall fret fentry fnext fexec fbreak contained

"""""""""""""""""""""""""""
" Hihglight Group Linkage "
"""""""""""""""""""""""""""

hi link rlComment       Comment
hi link rlTodo          Todo

hi link rlSString       rlLiteral
hi link rlDString       rlLiteral
hi link rlLiteral       String
hi link rlCharClass     rlRegex
hi link rlSlashRegex    rlRegex
hi link rlRegex         Special
hi link rlCodeOp        Operator
hi link rlCodeVar       Constant
hi link rlBuiltin       Constant
hi link rlAction        Structure

hi link rlKeyword       Structure
hi link rlOperator      Operator
hi link rlWriteWhatOp   Operator
hi link rlWriteOp       rlMachineDelim
hi link rlWritePercents rlMachineDelim
hi link rlMachineDelim  Preproc

let b:current_syntax = "ragel"
