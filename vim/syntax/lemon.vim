" Vim syntax file.
"
" Highlights source code of the lemon parser generator.
"
" Will highlight C or C++ inside rule action code depending on lemon_use_c.
" Recognises errors in identifiers.  See the end of this file for the default
" highlighting choices (it's quite colourfull if that bothers you).
"
" Vars are as follows.
"
" - lemon_use_c - use C instead of C++ for actions.
" - lemon_space_errors - show trailing spaces as errors.  Note that it should
"   also respect the C errors (see c.vim).
"   - lemon_no_trail_space_error - turns off trailing space errors
"   - lemon_no_tab_space_error - turns of trailing tab errors
"
" Things it can't do that could hypothetically be done.
"
" - can't show comment errors like C does (e.g. a lone end long comment)
" - can't recognise missing period at the end of rules (e.g.: rule { code } is
"   an error but rule . { code }" is not.
" - can't recognise an list of tokens (e.g. in %left ...) which doesn't have a
"   period at the end of it.
" - can't recognise when code has been given to a directive which doesn't need
"   it.
" - spaces at the end of lines (this one is easy)
" - it's probably quite slow -- it defines lots of syntax and then overrides it
"   later.
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

" Non-existing directive -- this must go first of course.
syn match lemonErrorDirective /%[a-z0-9_]\+/

" TODO:
"   I'm sure this lot can be optimised.  I don't think I can use 'display'
"   because it needs to match these in order to oeverride the error directive.

" Simple property directives.
syn match lemonBasicDirective '%destructor' 
syn match lemonBasicDirective '%name' 
syn match lemonBasicDirective '%stack_size' 
syn match lemonBasicDirective '%token_prefix'

" Directives which mess with tokens.
syn match lemonTokDirective '%left' 
syn match lemonTokDirective '%right' 
syn match lemonTokDirective '%nonassoc' 
syn match lemonTokDirective '%start_symbol' 
syn match lemonTokDirective '%type'

" Directives which take code.
syn match lemonBlockDirective '%include'
syn match lemonBlockDirective '%parse_accept' 
syn match lemonBlockDirective '%parse_failure' 
syn match lemonBlockDirective '%stack_overflow' 
syn match lemonBlockDirective '%syntax_error'
syn match lemonBlockDirective '%token_destructor'
" These two only take a subset of C (just a type) but it still works to
" highlight them as C.
syn match lemonBlockDirective '%token_type'
syn match lemonBlockDirective '%extra_argument'

" Really simple keywords
syn keyword lemonPredefined error
syn match   lemonEquals     /::=/
" Contained means they need to be "activated" with the contains= argument to
" some region (in this case it will be a comment).
syn keyword lemonTodo contained TODO XXX FIXME NOTE

" Moan if you put a lone semi-colon anywhere.  This works because the C code
" part is a region whih overrides this.
syn match  lemonError /;/
" Leading underscores are not allowed.
syn match  lemonError /_\+/

" Upper-case words become tokens.
syn match lemonToken     /[A-Z][A-Z0-9_]*/
syn match lemonRuleUse   /[a-z][a-z0-9_]*/
" Now un-match from RuleUse to get the rule definitions.
" TODO: this leaves the begning of the line highlighed.  That would be bad if the
" user has set their RuleDef class to have a coloured background.
syn match lemonRuleDef   /^\s*[a-z][a-z0-9_]*/

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
hi def link lemonErrorDirective    lemonError
hi def link lemonShortComment      lemonComment
hi def link lemonLongComment       lemonComment
hi def link lemonSpaceError        lemonError

" Default highlight groups: link generic groups to default groups..
hi def link lemonDirective Statement
hi def link lemonError     Error
hi def link lemonComment   Comment

" Stuff which is already generic enough.  Some artistic license here, I guess ;).
hi def link lemonTodo          Todo
hi def link lemonToken         Define
hi def link lemonRuleDef       Structure
hi def link lemonRuleUse       Constant
hi def link lemonEquals        Operator
hi def link lemonPredefined    Keyword

let b:current_syntax = 'lemon'
