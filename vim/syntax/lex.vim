" Vim syntax file
"
" Language:    Lex
" Maintainer:  James Webber <bunkerprivate@googlemail.com>
" Last Change: Jan, 2010
"
" Option:
"   lex_use_c : use C instead of C++ for definitions.

if exists("b:current_syntax")
  finish
endif

" I am going to use line continuations (the \ continuing commands.)
let s:cpo_save = &cpo
set cpo-=C

""""""""""""""""""""""""""
" Loading the Sub-Syntax "
""""""""""""""""""""""""""

" Load a sub-syntax into the sublanguage group.
fun! LexLoadSubSyntax(language_file)
  " Otherwise the file will not define anything.
  if exists("b:current_syntax")
    unlet b:current_syntax
  endif

  " Look for a file in ~/.vim first.  Docs imply you don't need to do this, so
  " maybe I've got it wrong.
  let s:relative_file = expand("<sfile>:p:h" . a:language_file)

  if filereadable(s:relative_file)
    exec 'syn include @lexSubLanguage ' . s:relative_file
  else
    exec 'syn include @lexSubLanguage ' . "$VIMRUNTIME/syntax/" . a:language_file
  end
endfun

" Read the C/C++ syntax to start with
if exists("lex_use_c")
  " runtime! syntax/c.vim
  call LexLoadSubSyntax("c.vim")
else
  " runtime! syntax/cpp.vim
  call LexLoadSubSyntax("cpp.vim")
endif

"""""""""""""""
" The Prelude "
"""""""""""""""
" Have to come first or it nukes the code region stuff.
syn match lexRegexReference /{[a-zA-Z_][a-z_A-Z0-9]*}/ contained
syn match lexRegexVar /^\s*\<[a-zA-Z_][a-z_A-Z0-9]*\>/ contained

" Despite using a pre-character match, we don't need to handle begining of line
" here because start of line can't have a regexp on it.
syn match lexRegexOp /\[[^\]]\+\]/ contained
" TODO: Won't highlight ops directly after something else.
syn match lexRegexOp /[^\\][|)(.?*]/ms=s+1 contained

" The "id regexp" part.
syn match lexRegexAssign /^\s*[a-zA-Z_]*.*$/ contained contains=lexRegexReference,lexRegexVar,lexRegexOp

syn match lexDirective /%[a-z]\+/ contained

" The beginning code in the prelude.
syn region lexPreludeCodeRegion matchgroup=lexPreludeCodeDelim start='%{' end='%}' contains=@lexSubLanguage contained

" Start of file to the first %%.  Options and so on.
syn cluster lexPreludeCodeCluster contains=lexPreludeCodeRegion,lexDirective,lexPreludeComment,lexRegexAssign
" Get rid of the ending %% because I need to match it for the rest.
syn region lexPreludeRegion start='\%^' matchgroup=lexPreludeEndDelim end='%%'me=e-2 contains=@lexPreludeCodeCluster

""""""""""""
" Comments "
""""""""""""

syn keyword lexTodo TODO XXX FIXME contained

" me=e-1 means match-end = real end - 1.  This gets rid of the star.
syn match lexLongCommentError display "/\*"me=e-1 contained
syn cluster lexCommentCluster contains=lexTodo,lexLongCommentError,@Spell

" Currently contained because rule comments can't be against the lefthand of the
" file.
syn region lexPreludeComment fold keepend contained
      \ matchgroup=lexPreludeComment start='/\*'
      \ end='\*/'
      \ contains=@lexCommentCluster

""""""""""""""
" Rules Part "
""""""""""""""

" TODO:
"   Somehow catch errors with indeitnation.  Perhaps just ^\s+^\s ?  It actually
"   only applies when you don't use the state region thing.
"
" TODO:
"   Operators of various kinds are not matched.
"
" TODO:
"   This way of writing it forces you to use the state features.  That might be
"   OK.  After all it's my syntax file and I always end up needing the state
"   features!  I could prolly make the other mode work, but it'd be really
"   difficult.
"
" TODO:
"   Code outside of action rules isn't exactly supported (it just dumps in
"   lexRulesRegion. Since I'm using sync from start perhaps I could create a new
"   region which matches end-code.  Perhaps I could also make it optional?  If !
"   syncfrom start then add the sublang to the lexRulesCluster.
"
" TODO:
"   End-of-rules delimiter is not highlighted.

syn region lexActionRegion matchgroup=lexActionDelimeter start='{' end='}' contained contains=@lexSubLanguage

syn region lexMatchString start='[^\\]"'ms=s+1 start='^"' end='"' skip='\\"' oneline contained
syn match lexMatchCancelled /\\[a-z".\-]/ contained
syn region lexMatchCharClass start='[^\\]\['ms=s+1 start='^\[' end='\]' skip='\\\]' oneline contained

syn match lexMatchExprVar /{[a-zA-Z_][a-zA-Z0-9_]\+}/ contained
syn cluster lexMatchRegionCluster contains=lexMatchString,lexMatchExprVar,lexMatchCharClass,lexMatchCancelled,lexStateRegionComment

" TODO: 
"   This only works properly if the matches are not indented.  It is too eager
"   to match the '{' end.  I want the lexMatchExprVar to consume that.  Fucking
"   vim bullshit.
syn region lexMatchRegion contained contains=@lexMatchRegionCluster transparent
      \ start='^' start='^\s\+' end='{'me=e-1 end=';' end='$' 

" Any non-ws at the start of the line.
"
"   Note: this actually only applies when you *don't* use the state region
"   features.
" syn region lexMatchRegion contained contains=@lexMatchRegionCluster
"       \ start='^[^ \t]'me=e-1 end='{'me=e-1 end=';' end='$' 

" ^<a,b,c,*>{ ... }
syn cluster lexStateRegionCluster contains=lexMatchRegion,lexActionRegion,lexStateRegionComment
syn region lexStateRegion matchgroup=lexStateGroupDelim start="^<[^>]\+>{" end="}" contained contains=@lexStateRegionCluster 

" The %% is pretty dodgy because it conflicts with the end of rules and start of
" final code.  Might be OK...
syn cluster lexRulesCluster contains=lexStateRegion
syn region lexRulesRegion matchgroup=lexRulesDelim start='^\s*%%' end='\%$' contains=@lexRulesCluster,@lexSubLanguage

syn region lexStateRegionComment fold keepend contained
      \ matchgroup=lexStateRegionComment start='/\*'
      \ end='\*/'
      \ contains=@lexCommentCluster


""""""""""""""""""""""""
" Default Highlighting "
""""""""""""""""""""""""

hi def link lexActionDelimeter  lexDelimiter
hi def link lexPreludeCodeDelim lexDelimiter
hi def link lexStateGroupDelim  lexDelimiter
hi def link lexRulesDelim       lexDelimiter
hi def link lexDelimiter        Delimiter

hi def link lexStateRegionComment lexComment
hi def link lexPreludeComment     lexComment
hi def link lexComment           Comment

hi def link lexDirective        Operator
hi def link lexTodo             Todo
hi def link lexLongCommentError Error
hi def link lexRegexReference   Define
hi def link lexRegexVar         Identifier
hi def link lexRegexOp          Special

hi def link lexMatchString      String
hi def link lexMatchExprVar     Define
hi def link lexMatchCharClass   Special
hi def link lexMatchCancelled   Special


" <c.vim> includes several ALLBUTs; these have to be treated so as to exclude lex* groups
" syn cluster cParenGroup   add=lex.*
" syn cluster cDefineGroup  add=lex.*
" syn cluster cPreProcGroup add=lex.*
" syn cluster cMultiGroup   add=lex.*

" TODO: 
"   Synchronization: I don't understand this but, but chances are I need it.
"   (Also in lemon, too?
" syn sync clear
" syn sync minlines=300
" syn sync match lexSyncPat grouphere  lexPatBlock "^%[a-zA-Z]"
" syn sync match lexSyncPat groupthere lexPatBlock "^<$"
" syn sync match lexSyncPat groupthere lexPatBlock "^%%$"

" Set this last because c.vim sets it too.
syn sync clear
syn sync fromstart

let b:current_syntax = "lex"

" Restore the line continuation
let &cpo = s:cpo_save
unlet s:cpo_save
