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
" - can't show comment errors like C does (e.g. a lone end long comment)
" - can't recognise missing period at the end of rules (e.g.: rule { code } is
"   an error but rule . { code }" is not.
" - can't recognise when code has been given to a directive which doesn't need
"   it.
" - doesn't match a lone token/rule as an error
" - badly formed rule-assignments, like "x y ::="
"
" Language:    Lemon
" Maintainer:  James Webber <bunkerprivate@googlemail.com>
" Last Change: Dec 2009.

if exists("b:current_syntax")
  finish
endif

" TODO:
"   Attempting to match a missing period at the end of rule.  Wants:
"
"   - an identifier followed by any kind of whitespace follwoed by a curly-brace
"   - unless the code is after a token directive
"   - don't stop code from being matched (at all).
"
"   The answer might be to explicitly implement all of the code-taking 
"   directives, then set any occurance of ". {" as an error, then add the code
"   block which I'll need some special method to make sure it onlymatches with
"   rule defs.
"
" TODO:
"   Missing period at the end of a token list?  It would be %directive followed
"   by any number of tokens followed by anything that isn't a token.  How do I
"   match the sub-error, though?  
"
"   I could do a region with start=%(any token directive) and a contains=the
"   error.  Could I optimise it so I *only* have to do that one match for
"   start= and set the start to he token directive?  This doesn't really help me
"   find the missing period, though.
"
"   Note: I think matchgroup is what sets start/end to be a particular group.

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

" TODO: would it be faster to have thest as some kind of or?

" Simple property directives.
syn match lemonBasicDirective '%destructor' 
syn match lemonBasicDirective '%name' 
syn match lemonBasicDirective '%stack_size' 
syn match lemonBasicDirective '%token_prefix'
syn match lemonBasicDirective '%start_symbol' 

" Directives which take code.
syn match lemonBlockDirective '%include'
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
syn keyword lemonPredefined   error
syn match   lemonEquals       /::=/
" Contained means they need to be "activated" with the contains= argument to
" some region (in this case it will be a comment).
syn keyword lemonTodo contained TODO XXX FIXME NOTE

" Moan if you put a lone semi-colon anywhere.  This works because the C code
" part is a region whih overrides this.
syn match  lemonError /;/
" Leading underscores are never allowed.
syn match  lemonError /_\+/

" We'll use this as a sub-match for places which don't allow upper-case words
" (i.e. grammar tokens) or lower-case words (i.e. rule names).  By using these
" contained, it means we don't highlight anything except the errors; otherwise
" you end up with, say, the whole start of the line highlighted.
"
" TODO: can't I store the regexp as an alias?
syn match lemonTokenPlacementError contained /[A-Z][A-Za-z0-9_]*/
syn match lemonRulePlacementError  contained /[a-z][A-Za-z0-9_]*/

" Used only in the multi-line directive regions.
syn match lemonDirectiveMissingPeriodError /%/ contained

" Upper-case/lower-case words are tokens and rules respectively.
"
" TODO:
"   Beause these are globally matched instead of contained, we can't match lone
"   tokens and rules as errors.  The solution would be to match these contained
"   in rule definitions only, but that is a bit tricky due to the
"   multi-line-ness and the fact that the user can forget to add the terminating
"   period.
syn match lemonTokenName    /[A-Z][A-Za-z0-9_]*/
syn match lemonRuleName     /[a-z][A-Za-z0-9_]*/
" Used only in x ::= expressions so we can have a different colour for
" rule names when they are in definitions.
syn match lemonRuleNameDef  /[a-z][A-Za-z0-9_]*/ contained


" Alias for shorter contains=
syn cluster lemonComments contains=lemonLongComment,lemonShortComment

" Find rule definitions and put the context-sensitive placement error and rule
" name def.  Transparent= don't colour it -- inherit color from whatever it's
" in.
"
" TODO: 
"   It is valid lemon to have x \n ::=.  This won't realise that.
syn match lemonRuleStart  /^[^:]\+::=/ transparent
      \ contains=lemonTokenPlacementError,lemonRuleNameDef,lemonEquals,@lemonComments

" Same again for rules placed in the token rule.  Matchgroup says "match the
" next start *and* end as something".  Therefore we use NONE to turn it off for
" the end.
"
" TODO: 
"   unintended side-effect: the missing period error detects and the rule
"   placecment error combine to 
syn region lemonTokens transparent 
      \ matchgroup=lemonTokDirective start="%left" start="%right" start="%nonassoc"
      \ matchgroup=NONE end='\.'
      \ contains=lemonRulePlacementError,lemonTokenName,@lemonComments,
      \          lemonDirectiveMissingPeriodError

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
" it a fold.
syn region lemonLongComment start='/\*' end='\*/' contains=@lemonCommentGroup,@Spell fold

if exists("g:lemon_use_c")
  call LemonLoadSubSyntax('c.vim')
else
  call LemonLoadSubSyntax('cpp.vim')
endif

" Keepend is needed to stop the sub-language consuming the curly brace and
" causing the entire file from the first {}-block to be highlighted as the
" sublang.
syn region lemonCode start="{" end="}" fold keepend contains=@lemonSubLanguage

" Default highlight groups: link specialised groups to generic ones.
hi def link lemonTokDirective      lemonDirective
hi def link lemonBlockDirective    lemonDirective
hi def link lemonBasicDirective    lemonDirective
hi def link lemonShortComment      lemonComment
hi def link lemonLongComment       lemonComment

hi def link lemonNonExistDirective    lemonError
hi def link lemonSpaceError           lemonError
hi def link lemonTokenPlacementError  lemonError
hi def link lemonRulePlacementError   lemonError
hi def link lemonDirectiveMissingPeriodError
                                    \ lemonError

" Default highlight groups: link generic groups to default groups..
hi def link lemonDirective Statement
hi def link lemonError     Error
hi def link lemonComment   Comment

" Stuff which is already generic enough.  Some artistic license here, I guess ;).
hi def link lemonTodo          Todo
hi def link lemonTokenName     Define
hi def link lemonRuleName      Constant
hi def link lemonRuleNameDef   Structure
hi def link lemonEquals        Operator
hi def link lemonPredefined    Keyword

let b:current_syntax = 'lemon'
