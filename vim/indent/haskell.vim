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
"   - g:haskell_gaps_zero -- causes indentation to be reset to zero when enter
"     is pressed twice.  This is often what haskell code looks like but could
"     catch you out.  The tradeoff is that When it's off, using ^F to manually
"     indent the file means that all of the 'where' clauses cause progressivly
"     bigger indents throughout the file.

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

  " We'll reuse these.
  let module_start_re = '^\s*module\>'
  let non_module_char_re = '[^ \ta-z0-9A-Z()]'
  let terminating_where_re = '\<where\s*$'
  let class_start_re = '^\s*\(class\|instance\|data\)'

  " This block of ifs makes sure that we can at least indent  the entire top of
  " the while without  the 'where' clasuses causing an indent every time they're
  " seen.
  if this_line =~ module_start_re
    return 0
  elseif this_line =~ class_start_re
    return 0
  elseif this_line =~ '^\s*import'
    return 0
  end

  " De-indent if there's a close bracket on its own.  Note: due to indentkeys,
  " this will happen as we type.
  if this_line =~ '^\s*[)}\]]\s*'
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
    while i > 0 
      if getline(i) !~ '^\s*data\>'
        return indent(i) + &shiftwidth
      end
      let i = i - 1
    endwhile
  end

  let prev_term_where = 0
  let this_term_where = 0
  let lone_where = 0

  let lone_where_re = '^\s*where\s*$'

  if this_line =~ lone_where_re
    let this_term_where = 1
    let lone_where = 1
  elseif this_line =~ terminating_where_re 
    let this_term_where = 1
    let lone_where = 0
  elseif prev_line =~ terminating_where_re
    let prev_term_where = 1
    let lone_where = 0
  end

  " A 'where' that we just wrote (due to indentkeys).  Indent to one more than
  " the module token if there is a module; otherwise one more than the current
  " indent.  This covers 'where' in a function or terminating a module def.
  "
  " We decide that there is *not* a module if we see any characters which aren't
  " allowed in module statements.
  "
  " This handles '=where'.
  if this_term_where == 1 || prev_term_where == 1
    " Don't indent the where if there's a lone closing bracket on the
    " earlier line.  Note: important to match before non_module_char_re
    " because they contain the same characters!  Note also: we only check
    " closest nonblank line above, not all the lines.
    if prev_line =~ '^\s*[\])}]\+\s*$'
      return indent(prev_lnum)
    endif

    if this_term_where == 1
      let i = prev_lnum
    else
      let i = prev_lnum - 1
    endif

    while i > 0 
      let line_i = getline(i)
      if line_i =~ module_start_re

        if this_term_where == 1
          if lone_where == 1
            " If it's on a line of its own then use module + 1 regardless of the
            " export brackets.
            return indent(i) + &shiftwidth
          else
            " Otherwise it must be a continuation of a long module line and
            " therefore the other indentation rules should have sotred *this
            " particular line* line out already.  (Note: this code is probably
            " unreachable becasue the ony other tokens that can go in are the
            " close brackets which match at a higher precedence.
            return indent(a:lnum)
          end
        else
          " If the where was on the previous line and said line was part of a
          " module declaration then we need to return to the indent of the
          " module ( zero usually)
          return indent(i)
        end
      elseif line_i =~ non_module_char_re
        " If we're not in a module then we need to indent whether this line is a
        " 'where' or we're on the line after one.
        return indent(prev_lnum) + &shiftwidth
      endif

      let i = i - 1
    endwhile

    " Be safe we could end up with very weird behavior if continuing to do other
    " matches.
    if i <= 0
      return indent(prev_lnum)
    end
  end

  " Indents from a class are always one.
  if prev_line =~ class_start_re
    return &shiftwidth
  end

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
  "
  "   I also need in and let etc. here.
  if prev_line =~ '[\-!$%^&*(|=~?/\\{:><\[]\s*$' || prev_line =~ '\<do\s*$' 
    return indent(prev_lnum) + &shiftwidth
  endif

  " Default case if we get here is to use the last line.  When this is blank, it
  " *usually* means we're on a new function but this is pretty error prone when
  " we are re-indenting the whole file.  It means pressing enter twice counts as
  " a new function.
  if exists("g:haskell_gaps_zero") && g:haskell_gaps_zero > 0
    return indent(a:lnum - 1)
  else
    " Therefore we can use the last non-blank line.
    return indent(prev_lnum)
  end
endfunction
