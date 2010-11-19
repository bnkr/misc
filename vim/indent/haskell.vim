" Vim indent file
"
" Language:     Haskell
" Author:       James Webber <bunkerprivate@gmail.com>
" Last Change:  2010-11-15
"
" Description:
"
"   Indents haskell code. See comments in the file to work out what it's doing.
"
" Variables:
"
"   None.

if exists('b:did_indent')
  " finish
endif
let b:did_indent = 1

setlocal indentkeys=!^F,o,O,0},0],0),=deriving,=where
setlocal indentexpr=GetHaskellIndent(v:lnum)

fun! GetHaskellIndent(lnum)
  " Hit the start of the file, use zero indent (we need one line before us
  " before we can do any useful indentation)
  if a:lnum < 1
    return 0
  endif

  let prev_lnum = prevnonblank(a:lnum - 1)
  let prev_line = getline(prev_lnum)
  let this_line = getline(a:lnum)

  " De-indent if there's a close bracket on its own.  Note: due to indentkeys,
  " this will happen as we type.
  if this_line =~ '^\s*[)}\]]\s*$'
    let leading_ws = match(prev_line, '[^ ]')

    let open_brack_re = "[{(\[]\s*$"

    " '{\n}' is a special case because the '\n' will have caused us to indent
    " thus meaning we have to go back one.
    if prev_line =~ open_brack_re
      return indent(prev_lnum)
    else
      return indent(prev_lnum) - &shiftwidth
    endif
  endif

  " Set the indent to one more than the closest 'data' declaration.  If there is
  " no data found then leave it as is.  Note: the *start* of the line is checked
  " because we'd expect to see an open bracket after this if we're doing a
  " re-indent with CTRL+F or whatever.
  if this_line =~ '^\s*deriving\>'
    let i = prev_lnum
    while i > 0 && getline(i) !~ '^\s*data\>'
      let i = i - 1
    endwhile

    if i > 0
      return indent(i) + &shiftwidth
    endif
  end

  " A 'where' on its own is an indent
  if this_line =~ '^\s*where$'
    return indent(prev_lnum) + &shiftwidth
  endif

  " Indent if the line terminates on one of the operators.  We also need to do
  " this after the open brack bit to avoid a conflict when calling from the '}'
  " indentkeys.
  "
  " TODO:
  "   prolly needs modification to deal with sequence blocks operators becaue
  "   thay can come at end of line and don't warrant an indent.  Could be
  "   avoided from this match by specifying only one character operators next to
  "   whitespace.  We'd have to add in the "->" and "=>" things, though so it
  "   prolly comes to roughly the same thing..
  if prev_line =~ '[\-!$%^&*(|=~?/\\{:><\[]\s*$' || prev_line =~ '\<do\s*$' 
    return indent(prev_lnum) + &shiftwidth
  endif

  " Indent after a module which hasn't been terminated with a where
  if prev_line =~ '^\s*module\>' && prev_line !~ '\<where\s*$'
    return indent(prev_lnum) + &shiftwidth
  endif

  " Indent after a terminating where excluding a where which appears to be part
  " of a module declaration.  We decide what a module declaration is based on
  " the fact that it's not allowed an equals operator in it whereas all
  " functions will have one.
  if prev_line =~ "\<where\s*$"
    let i = prev_lnum
    while i > 0 
      if getline(i) =~ '\<module\>'
        return indent(prev_lnum) + &shiftwidth
      elseif getline(i) =~ '[=]'
        return indent(prev_lnum)
      end
    endwhile
  endif

  " Default case if we get here is to leave the indent unmodified.
  return indent(prev_lnum)
endfunction
