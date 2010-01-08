" Vim syntax file.
"
" Highlights source code of the lemon parser generator, including C or C++
" source code in the code blocks.
"
" Will highlight C or C++ inside rule action code depending on lemon_use_c.
"
" Recognises errors:
"
" - in identifiers (e.g. leading underscore)
" - tokens (upper-case identifiers) placed at the start of rules
" - rules (lower-case identifiers) in places where they are not allowed
" - missing periods at the end of token lists (%left, %right etc.)
" - missing preiods at the end of rules before code (but not at the end of
"   rules with no code).
"
" Vars are as follows.
"
" - lemon_use_c - use C instead of C++ for actions.
" - lemon_space_errors - show trailing spaces as errors.  Note that it should
"   also respect the C errors (see c.vim).
"   - lemon_no_trail_space_error - turns off trailing space errors
"   - lemon_no_tab_space_error - turns of trailing tab errors
"
" Highlighting limitations (which could hypothetically be solved):
"
" - can't recognise missing period at the end of rules which have no code (but
"   the highlighting should look weird anyway)
" - can't recognise when code has been given to a directive which doesn't need
"   it.
" - doesn't match a lone lower-case as an error, including rules which look like
"   x y ::= z (but the highlighting looks weird).
"
" Language:    Lemon
" Maintainer:  James Webber <bunkerprivate@googlemail.com>
" Last Change: Dec 2009.

if exists("b:current_syntax")
  finish
endif

" I am going to use line continuations (the \ continuing commands.)
let s:cpo_save = &cpo
set cpo-=C

" Load a sub-syntax into the lemonSubLanguage group.
fun! LemonLoadSubSyntax(language_file)
  " Otherwise the file will not define anything.
  if exists("b:current_syntax")
    unlet b:current_syntax
  end

  " Look for a file in ~/.vim first.  Docs imply you don't need to do this, so
  " maybe I've got it wrong.
  let s:relative_file = expand("<sfile>:p:h" . a:language_file)

  if filereadable(s:relative_file)
    exec 'syn include @lemonSubLanguage ' . s:relative_file
  else
    exec 'syn include @lemonSubLanguage ' . "$VIMRUNTIME/syntax/" . a:language_file
  end
endfun

" Non-existing directive this gets overridden by the real ones.
syn match lemonNonExistDirective /%[a-z0-9_]\+/

" TODO: 
"   Would it be faster to have these as some kind of or?  It must match all of
"   them and override later...

" Simple property directives.
syn match lemonBasicDirective '%name' 
syn match lemonBasicDirective '%stack_size' 
syn match lemonBasicDirective '%token_prefix'
syn match lemonBasicDirective '%start_symbol' 
" These aren't documented, but they do work.
syn match lemonBasicDirective '%ifdef' 
syn match lemonBasicDirective '%endif' 

" Directives which take code.
syn match lemonBlockDirective '%include'
syn match lemonBlockDirective '%destructor' 
syn match lemonBlockDirective '%parse_accept' 
syn match lemonBlockDirective '%parse_failure' 
syn match lemonBlockDirective '%stack_overflow' 
syn match lemonBlockDirective '%syntax_error'
syn match lemonBlockDirective '%token_destructor'
" These only take a subset of C (just a type) but it still works to
" highlight them as C.
syn match lemonBlockDirective '%type'
syn match lemonBlockDirective '%token_type'
syn match lemonBlockDirective '%extra_argument'

" Really simple keywords
syn keyword lemonPredefined   error contained
syn match   lemonEquals       /::=/ contained
" Contained means they need to be "activated" with the contains= argument to
" some region (in this case it will be a comment).
syn keyword lemonTodo contained TODO XXX FIXME NOTE

" Moan if you put a lone semi-colon anywhere.  This works because the C code
" part is a region whih overrides this.
syn match  lemonError /[;.]/
" Leading underscores are never allowed.
syn match  lemonError /\<_\+/ms=s+1
syn match  lemonError /^_\+/

" We'll use this as a sub-match for places which don't allow upper-case words
" (i.e. grammar tokens) or lower-case words (i.e. rule names).  By using these
" contained, it means we don't highlight anything except the errors; otherwise
" you end up with, say, the whole start of the line highlighted.
syn match lemonTokenPlacementError contained /[A-Z][A-Za-z0-9_]*/
syn match lemonRulePlacementError  contained /[a-z][A-Za-z0-9_]*/

" Upper-case/lower-case words are tokens and rules respectively.
syn match lemonTokenName    /[A-Z][A-Za-z0-9_]*/ contained
syn match lemonRuleName     /[a-z][A-Za-z0-9_]*/ contained
" Used only in x ::= expressions so we can have a different colour for
" rule names when they are in definitions.
syn match lemonRuleNameDef  /[a-z][A-Za-z0-9_]*/ contained

" Alias for shorter contains=
syn cluster lemonComments contains=lemonLongComment,lemonShortComment

" For "rule(varname) ::= ..."
syn match lemonRuleVar /[a-zA-Z][a-zA-Z_0-9]*/ contained
syn match lemonRuleVarMatch /(\([^)]\|\n\)*)/ contained
      \ contains=lemonRuleVar

" Find rule definitions and put the context-sensitive placement error and rule
" name def.  Transparent= don't colour it -- inherit color from whatever it's
" in.  me=e-3 removes the equals which we need in otder to math the ruleEnd
" group.
syn match lemonRuleStart  /\<[a-z][A-Za-z0-9_]*\(\(\s\|\n\)*(\([^)]\|\n\)*)\)\?\(\s\|\n\)*::=/me=e-3 transparent 
      \ contains=lemonTokenPlacementError,lemonRuleNameDef,lemonRuleVarMatch,@lemonComments

syn match lemonRuleMissingPeriodError     /{/ contained

syn match lemonEqualsPlacementError /::=/ contained

syn region lemonRuleEnd transparent keepend
      \ matchgroup=lemonEquals start='::='
      \ matchgroup=NONE end='\.'
      \ contains=lemonRuleMissingPeriodError,lemonTokenName,lemonRuleName,lemonRuleName,
      \   lemonTokenName,lemonEqualsPlacementError,lemonPredefined,lemonRuleVarMatch

" Used only in the multi-line directive regions.  Note: a side-effect of this is
" that the missing period error and the placement errors combine to match the
" entire directive.  It's ok if you have set nolist but otherwise the trailing
" spaces aren't highlighted and it looks a bit confusing.
syn match lemonDirectiveMissingPeriodError /\([^\.]\)\(\s\|\n\)\+%/ contained

" Same again for rules placed in the token rule.  Matchgroup says "match the
" next start *and* end as something".  Therefore we use NONE to turn it off for
" the end.
syn region lemonTokDirectiveRegion transparent keepend
      \ matchgroup=lemonTokDirective start="%left" start="%right" start="%nonassoc"
      \ matchgroup=NONE end='\.'
      \ contains=lemonRulePlacementError,lemonTokenName,@lemonComments,
      \          lemonDirectiveMissingPeriodError

syn match lemonPrecedenceDecl /\[[^\]]\+\]/
      \ contains=lemonRulePlacementError,lemonTokenName

if exists("lemon_space_errors")
  if ! exists("lemon_no_trail_space_error")
    syn match lemonSpaceError display excludenl "\s\+$"
  endif
  if ! exists("lemon_no_tab_space_error")
    syn match lemonSpaceError display " \+\t"me=e-1
  endif
endif

" Since there are muliple comment types, this is used as an contains=@.  Cluster
" is basically just an alias (but you can add to it with the add= argument)
syn cluster lemonCommentGroup contains=lemonTodo

" Single line comments.
syn match lemonShortComment +//.*$+  contains=@lemonCommentGroup,@Spell

" Multi-line (c-style) comments.  If foldmethod is syntax, then this will make
" it a fold.  Putting matchgroup in stops the long comments starts being
" highlighted as comment start errors.
syn region lemonLongComment fold keepend
      \ matchgroup=lemonLongComment start='/\*' 
      \ end='\*/' 
      \ contains=@lemonCommentGroup,@Spell,lemonLongCommentError 

" me=e-1 means match-end = real end - 1.  This gets rid of the star.
syn match lemonLongCommentError display "/\*"me=e-1 contained

if exists("g:lemon_use_c")
  call LemonLoadSubSyntax('c.vim')
else
  call LemonLoadSubSyntax('cpp.vim')
endif

" OK, aparently you need to set a matchgroup or the region will end at the first
" close-curly bracket.  What the fuck, vim.  What the fuck.
syn region lemonCodeRegion matchgroup=Operator start="{" end="}" transparent contains=@lemonSubLanguage

" Default highlight groups: link specialised groups to generic ones.
hi def link lemonTokDirective      lemonDirective
hi def link lemonBlockDirective    lemonDirective
hi def link lemonBasicDirective    lemonDirective
hi def link lemonShortComment      lemonComment
hi def link lemonLongComment       lemonComment

hi def link lemonEqualsPlacementError lemonError
hi def link lemonNonExistDirective    lemonError
hi def link lemonSpaceError           lemonError
hi def link lemonTokenPlacementError  lemonError
hi def link lemonRulePlacementError   lemonError
hi def link lemonDirectiveMissingPeriodError
                                    \ lemonError
hi def link lemonRuleMissingPeriodError
                                    \ lemonError
hi def link lemonLongCommentError     lemonError

" Default highlight groups: link generic groups to default groups..
hi def link lemonDirective Statement
hi def link lemonError     Error
hi def link lemonComment   Comment

" Stuff which is already generic enough.  Some artistic license here, I guess ;).
hi def link lemonTodo           Todo
hi def link lemonTokenName      Define
hi def link lemonRuleName       Constant
hi def link lemonRuleNameDef    Structure
hi def link lemonEquals         Operator
hi def link lemonPredefined     Keyword
hi def link lemonRuleVar        Special
hi def link lemonPrecedenceDecl Operator

let b:current_syntax = 'lemon'

" Restore the line continuation
let &cpo = s:cpo_save
unlet s:cpo_save
