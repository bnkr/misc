" Vim indent file
"
" Language:     Haskell
" Author:       James Webber <bunkerprivate@gmail.com>
" Last Change:  2010-11-15
"
" Description:
"
"   Indents Haskell code. See comments in the file to work out what it's doing.
"
"   This is a pretty slow indent file.  There are *lots* of things to try and
"   match, and there are some loops to find context but mostly that'll only
"   apply regexes to two or three lines.
"
" Variables:
"
"   - g:haskell_gaps_zero -- causes indentation to be reset to zero when enter
"     is pressed twice.  This is often what haskell code looks like but could
"     catch you out.  The tradeoff is that When it's off, using ^F to manually
"     indent the file means that all of the 'where' clauses cause progressivly
"     bigger indents throughout the file.
"
"     Even with this variable on, a 'where' clause will always indent you back
"     to the right position, though.
"
" Todo:
"
"   - lots of Haskellists like to indent ased on the previous '=' operator.
"     It's pretty hard to do it because you don't know what continues a function
"     or not.
"   - this file uses space-specific stuff (e.g indenting the length of a
"     'where').  It should turn spaces on instead of tabs depending on a global
"     variable, and disable he space-specific stuff if that var is not set.


" TODO:
"   Consider
"
"   f = do
"     blah
"     blah
"       where
"         x = y
"
"   The 'where' appears to apply to the second expression, but in reality it
"   applies to the entire 'do' block.
"
" TODO:
"   if/case, a bit like 'in'.  Prolly only 'case' is wanted.

if exists('b:did_indent')
  " finish
endif
let b:did_indent = 1

setlocal indentkeys=!^F,o,O,0},0],0),=deriving,=where,=in,<=>
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

  " We have to avoid re-indenting this line unless we're dealing with a 'let',
  " which has special handling in order to make let in 'do' work.
  "
  " This has a side-effect that 'f =\n' won't be modified when manually
  " re-indenting.
  if this_line =~ '=$'
    " If the previous non-blank line has a 'let' with stuff after it and no 'in'
    " then this is an equation which we must assume should line up with the
    " above 'let' equation.
    if prev_line =~ '\<let\>\s\+[^ ]' && prev_line !~ '\<in\>'
      return match(prev_line, '\<let\>') + 4
    end

    " Ideally we would always exit here, but unfortunately, I can't tell if it
    " was '=' that was pressed or we're pressing <enter> in the middle of a line
    " which has an '=' on the end.  Thereofre, I have to keep going and try more
    " matches and hope for the best.
  endif

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
      if getline(i) =~ '^\s*data\>'
        return indent(i) + &shiftwidth
      end
      let i = i - 1
    endwhile
  endif

  " Any kind of 'in' indent needs to look for a previous let.
  if this_line =~ '\<in\>'
    let i = prev_lnum
    while i > 0
      " The 'let' can be anyywhere on the line (eg 'f = let a = b') so we have
      " to be lenient.  Also we don't care if there is stuff after the let.
      if getline(i) =~ '\<let\>'
        return indent(i)
      endif

      let i = i - 1
    endwhile

    " Only get here in case of errors when doing =in.
    return indent(a:lnum)
  endif

  " This is a manual indent of a where with trailing stuff.  Note: this night
  " conflict with things later as it doesn't do much checking, but the only
  " other places where you can have 'where' with trailing stuff are errors so
  " it's not a big deal.
  if this_line =~ '\<where\s\+[^ ]\+'
    return indent(prev_lnum)  +  &shiftwidth
  end

  let this_term_where = 0
  let lone_where = 0
  let where_found = 0

  let lone_where_re = '^\s*where\s*$'

  if this_line =~ lone_where_re
    let this_term_where = 1
    let lone_where = 1
    let where_found = 1
  elseif this_line =~ terminating_where_re
    let this_term_where = 1
    let where_found = 1
  elseif prev_line =~ terminating_where_re
    let where_found = 1
  end

  " A 'where' that we just wrote (due to indentkeys).  Indent to one more than
  " the module token if there is a module; otherwise one more than the current
  " indent.  This covers 'where' in a function or terminating a module def.
  "
  " We decide that there is *not* a module if we see any characters which aren't
  " allowed in module statements.
  "
  " This handles '=where' and 'where' terminating the previous line.
  if where_found == 1
    " Don't indent the where if there's a lone closing bracket on the
    " earlier line.  Note: important to match before non_module_char_re
    " because they contain the same characters!  Note also: we only check
    " closest nonblank line above, not all the lines.
    if prev_line =~ '^\s*[\])}]\+\s*$'
      return indent(prev_lnum)
    endif

    " We always have to s tart on the preious line because, even if we just
    " matched prev_term_where, there might be a module token on that line.
    let i = prev_lnum

    while i > 0
      let line_i = getline(i)
      " TODO:
      "   Need to check for interface/class definitions as well because they
      "   have the same rules.
      if line_i =~ module_start_re

        if this_term_where == 1
          if lone_where == 1
            " If it's on a line of its own then use module + 1 regardless of the
            " export brackets.
            return indent(i) + &shiftwidth
          else
            " Otherwise it must be a continuation of a long module line and
            " therefore the other indentation rules should have sorted *this
            " particular line* line out already.  (Note: this code is probably
            " unreachable becasue the only other tokens that can go in are the
            " close brackets which match at a higher precedence.
            return indent(a:lnum)
          end
        else
          " If the where was on prev_line and said line was part of a module
          " declaration then we need to return to the indent of the module
          " (always zero)
          return 0
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

  " Comments don't do anything specia.
  if prev_line =~ '^\s*--'
    return indent(prev_lnum)
  endif

  " Indents from a class/data etc are always one.  Indent after a module which
  " hasn't been terminated with a where.  The 'without a where' part is implicit
  " because we already matched terminating wheres.
  if prev_line =~ class_start_re || prev_line =~ module_start_re
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
  "
  " TODO:
  "   this causes comments to get indented (e..g TODO:<enter>)
  if prev_line =~ '[\-!$%^&*(|=~?/\\{:><\[]\s*$' || prev_line =~ '\<\(do\|let\|in\)\s*$'
    return indent(prev_lnum) + &shiftwidth
  endif

  " A where/let/do with stuff coming after it usually wants an indentation to
  " match the position where the stuff trailing the 'where' started.  Let needs
  " special handling and is done when an equals character is written.
  "
  " TODO: why can't I use brackets and a submatch?
  "
  " TODO: nly works when NOT using tabs.  Need to deal with that somehow.
  if prev_line =~ '\<where\s\+[^ ]\+'
    return match(prev_line, '\<where\>') + 6
  elseif prev_line =~ '\<do\s\+[^ ]\+'
    return match(prev_line, '\<do\>') + 3
  elseif prev_line =~ '\<in\s\+[^ ]\+'
    return match(prev_line, '\<in\>') + 3
  end

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
