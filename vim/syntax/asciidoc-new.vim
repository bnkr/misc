" Vim syntax file.
"
" Language:    Asciidoc
" Maintainer:  James Webber <bunkerprivate@googlemail.com>
" Last Change: Jan, 2010
"
" Options:
"
" - asciidoc_space_errors -- define if you want \s+\n to be reported as an
"   error.
"   - asciidoc_no_trail_space_error -- don't report spaces as errors.
"   - asciidoc_no_tab_space_error -- don't report tabs as errors
" - asciidoc_custom_colors
"   - use a custom colorscheme which can make more sense than using the default
"     groups, but also might look naff on your terminal.  If this isn't set then
"     the default groups (Define, Structure) etc. are used under the assumption
"     that they will at least look visible on the screen and match up together.

if exists("b:current_syntax")
  finish
end

let s:cpo_save = &cpo
set cpo-=C

"""""""""""
" Headers "
"""""""""""

" TODO: 
"   If you make a typo on the underline line and then press enter, the line
"   remains un-highlighted.

syn match asciidocTitle         /^[a-z0-9A-Z].\+\n=\+\s*\n/
syn match asciidocSection       /^[a-z0-9A-Z].\+\n-\+\s*\n/
syn match asciidocSubSection    /^[a-z0-9A-Z].\+\n\~\+\s*\n/
syn match asciidocSubSubSection /^[a-z0-9A-Z].\+\n\^\+\s*\n/

hi link asciidocTitle         Define
hi link asciidocSection       Structure
hi link asciidocSubSection    asciidocSection
hi link asciidocSubSubSection asciidocSection

""""""""""
" Quotes "
""""""""""

" Technically lone quotes aren't an error but they're unlikely to be what the
" user really wanted.  
"
" TODO:
"   This won't ever match a lone `` because the quote region always consumes it.
"   Perhaps I should use a match instead of a region?  (But then how do I
"   organise skip ends?)
syn match asciidocQuoteError /``/
syn match asciidocQuoteError /''/

" It seems to be impossible to match ``...\n\n as an error because you can't
" write "... which doesn't have '' in it".  Anyway, you'll end up with huge
" blocks of errors while you're writing stuff which will become valid when you
" finish which I don't like.
"
" TODO:
"   Why can't I match word boundaries in here?
syn region asciidocQuoteRegion matchgroup=asciidocDblQuoteDelim transparent
      \ start=/``/ end='\n\n' end="''" 

hi link asciidocQuoteError asciidocError

hi link asciidocError Error

" Matches what LaTeX does.
hi link asciidocDblQuoteDelim String

"""""""""""""""""""""""""
" Regions in Paragraphs "
"""""""""""""""""""""""""

syn match asciidocPassthruDelim /`/ contained

" Keepend or the delim causes it to fail to end.
syn region asciidocPassthru keepend
      \ start='`[^`]'me=e-1 end='`' end='\n\n'
      \ contains=asciidocPassthruDelim 

hi link asciidocPassthruDelim Delimiter
hi link asciidocPassthru SpecialComment

""""""""""""""""""
" Verbatim parts "
""""""""""""""""""

" TODO: for source,cpp load  he C++ sub-language.
syn region asciidocDelimitedVerbatim matchgroup=Normal start='\[source,.\+\n-\+$' end=/^-\+$/

hi link asciidocDelimitedVerbatim asciidocVerbatim
hi link asciidocVerbatim Comment

""""""""""""""""""""""""""
" Blocks of a named type "
""""""""""""""""""""""""""

" TODO: note, warning, etc.

""""""""""""""""""""""""""""""""""
" Optional trailing space errors "
""""""""""""""""""""""""""""""""""

if exists("asciidoc_space_errors")
  if ! exists("asciidoc_no_trail_space_error")
    syn match asciidocSpaceError display excludenl "\s\+$"
  endif 
  if ! exists("asciidoc_no_tab_space_error")
    syn match asciidocSpaceError display " \+\t"me=e-1
  endif
endif

"""""""""""""""""""
" Synchronisation "
"""""""""""""""""""

" TODO: 
"   sync at ^-\+*$/ (but first work out how syncing works!)  I think it's
"   essentially where you look backwards for a bit to work out what
"   region you're actually in right now.  Therefore, simply saying "-" is no
"   good because ou could be in any region.

" Just a guess, but most docs are unlikely to have more than screen + 30 lines
" of documentation (on account of it being bloody impossible to read ^^).
syn sync minlines=30

""""""""""""""""""""""""""""
" Default highlight groups "
""""""""""""""""""""""""""""

if exists("asciidoc_custom_colors")
endif

""""""""""""
" Epilogue "
""""""""""""

let b:current_syntax = "asciidoc"

" Restore the line continuation settings
let &cpo = s:cpo_save
unlet s:cpo_save
