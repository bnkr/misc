" Vim syntax file.
"
" Language:     CMake
" Author:       James Webber
" Licence:      The CMake license applies to this file. See
"               http://www.cmake.org/HTML/Copyright.html
"               This implies that distribution with Vim is allowed
"
" This file is very loosely based on the original cmake.vim by Andy Cedilnik (I
" nicked the names of constants and some of the regexps from there).
"
" I use the convention that groups ending Region and Match shouldn't be coloured
" -- they're for utility; the submatches do the actual colouring..
"
" Vars:
"
" - cmake_space_error
"   - cmake_no_trail_space_error
"   - cmake_no_tab_space_error
" - cmake_extra_predefs -- extra highlighting for a subset of cmake functions.
"   This will recognise the named parameter arguments and possibly some extra
"   errors.  Very little is implemented.
" - cmake_ending_errors -- search for mismtached macro/endmacro etc.  These kind
"   of things are always iffy in vim; you might need to up the sync level a lot.

if exists("b:current_syntax")
  finish
endif

" Main Todo:
"
" - error checking regions (cmake_ending_errors) aren't working properly -- they
"   don't recurse correctly.
"
" - Colours aren't that nice.  I think I prefer function calls as normal, and
"   any other identifier as identifiers.
"
" - Predefined vars (or at least system vars).  Colour of Define I suppose;
"   constant could be better as it is different from the substitutions.
"

" Line continuations will be used.
let s:cpo_save = &cpo
set cpo-=C

"""""""""""""""
" Basic stuff "
"""""""""""""""
syn keyword cmakeTodo TODO FIXME XXX contained
syn match cmakeComment /#.*$/ contains=cmakeTodo,@Spell
" According to the old cmake.vim, this really is all the escapes which are
" allowed.
syn match cmakeEscape /\\[nt\\"]/ contained
syn region cmakeString start='"' skip='\\"' end='"' contained contains=cmakeSubstitution,cmakeEscape

" This is recursive, so it has to be a region.  Note that this one doesn't
" keepend because the sub-substitution should consume the close bracket.
syn region cmakeSubstitution start='\${' end='}' oneline contains=cmakeSubstitution

" Non-contained and with a low precedence to be the default match.  A
" sub-match is used to avoid highlighting the (possible) whitespace, which
" would look naff if the match has a special background.
syn match cmakeUserFunctionCall /[a-zA-Z0-9_]\+/ contained
syn match cmakeFunctionCallMatch /[a-zA-Z0-9_]\+\(\s\|\n\)*(/me=e-1 contains=cmakeStatementFunction,cmakePredefFunction,cmakeUserFunctionCall

" An uncontained match for bad characters; i.e. those which aren't allowed
" outside paren'ed code.
syn match cmakeCharError /[;.{}]/

""""""""""""""""""""""""""""""""""""""""""""""""""""
" CMake instrinsics and context-sensitive keywords "
""""""""""""""""""""""""""""""""""""""""""""""""""""

syn case ignore
" This is only used in the if/elseif regions.
syn keyword cmakeOperator contained
      \ IS_ABSOLUTE IS_DIRECTORY EXISTS
      \ IS_NEWER_THAN
      \ DEFINED
      \ COMMAND
      \ AND OR NOT
      \ STREQUAL STRGREATER STRLESS MATCHES
      \ EQUAL GREATER LESS
      \ VERSION_LESS VERSION_GREATER VERSION_EQUAL
      \ TARGET

" Cmake's intrinsic functions.  This is contained in the user-function calls.
" It might later be overridden by special regions for a particular cmake
" function.
"
" NOTE: I think I could use nextgroup= to highlight known arguments to cmake
" functions.
syn keyword cmakePredefFunction contained
      \ ADD_CUSTOM_COMMAND ADD_CUSTOM_TARGET ADD_DEFINITIONS ADD_DEPENDENCIES 
      \ ADD_EXECUTABLE ADD_LIBRARY ADD_SUBDIRECTORY ADD_TEST AUX_SOURCE_DIRECTORY 
      \ BUILD_COMMAND BUILD_NAME CMAKE_MINIMUM_REQUIRED CONFIGURE_FILE CREATE_TEST_SOURCELIST 
      \ ENABLE_LANGUAGE ENABLE_TESTING 
      \ EXEC_PROGRAM EXECUTE_PROCESS EXPORT_LIBRARY_DEPENDENCIES FILE FIND_FILE 
      \ FIND_LIBRARY FIND_PACKAGE FIND_PATH FIND_PROGRAM FLTK_WRAP_UI 
      \ GET_CMAKE_PROPERTY GET_DIRECTORY_PROPERTY GET_FILENAME_COMPONENT GET_SOURCE_FILE_PROPERTY 
      \ GET_TARGET_PROPERTY GET_TEST_PROPERTY INCLUDE INCLUDE_DIRECTORIES INCLUDE_EXTERNAL_MSPROJECT 
      \ INCLUDE_REGULAR_EXPRESSION INSTALL INSTALL_FILES INSTALL_PROGRAMS INSTALL_TARGETS LINK_DIRECTORIES 
      \ LINK_LIBRARIES LIST LOAD_CACHE LOAD_COMMAND MAKE_DIRECTORY MARK_AS_ADVANCED MATH 
      \ MESSAGE OPTION OUTPUT_REQUIRED_FILES PROJECT QT_WRAP_CPP QT_WRAP_UI REMOVE REMOVE_DEFINITIONS 
      \ SEPARATE_ARGUMENTS SET SET_DIRECTORY_PROPERTIES SET_SOURCE_FILES_PROPERTIES SET_TARGET_PROPERTIES 
      \ SET_TESTS_PROPERTIES SITE_NAME SOURCE_GROUP STRING SUBDIR_DEPENDS SUBDIRS TARGET_LINK_LIBRARIES 
      \ TRY_COMPILE TRY_RUN UNSET USE_MANGLED_MESA UTILITY_SOURCE VARIABLE_REQUIRES VTK_MAKE_INSTANTIATOR 
      \ VTK_WRAP_JAVA VTK_WRAP_PYTHON VTK_WRAP_TCL WRITE_FILE GET_PROPERTY SET_PROPERTY
      \ CMAKE_POLICY

" I consider break() etc. to be special, and should get operator colours.
syn keyword cmakeStatementFunction contained
      \ BREAK RETURN 

syn keyword cmakeRepeat
      \ FOREACH ENDFOREACH WHILE ENDWHILE
" If and elseif are redundant because they are matchgroups of the if region
" match.
syn keyword cmakeConditional
      \ WHILE ENDWHILE ELSE ENDIF
" Again, these must be matched separately and MACRO/FUNCTION is redundant.
syn keyword cmakeFuncDefine
      \ ENDMACRO ENDFUNCTION

" Constants are case sensitive.
syn case match
syn keyword cmakeConstant contained
      \ TRUE FALSE ON OFF

" TODO: 
"   Match predefined variables and system variables as contained.  We can't have
"   them uncontained or we'll end up matching them in places we don't want.

syn match cmakeEnvironmentSet /ENV{[a-zA-Z0-9_]*}/   contained
syn match cmakeEnvironmentSub /\$ENV{[a-zA-Z0-9_]*}/ contained

""""""""""""""""""""""""""""""
" Parenthesised code regions "
""""""""""""""""""""""""""""""

" Alias for everthing that can go in parens, but not including things like
" operators or special arguments.
"
" Note: not exactly perfect because cmakeEnvironmentSet is only allowed in a
" set().
syn cluster cmakeParenCode 
      \ contains=cmakeSubstitution,cmakeString,cmakeComment,cmakeConstant,
      \   cmakeEnvironmentSet,cmakeEnvironmentSub

" Set the match start to skip the leading character.  The character is needed
" because we don't want to match an lparen at the very start of the region.
syn match cmakeParenError /.(/ms=s+1 contained

" The basic function parameters.
syn region cmakeParenRegion start='(' end=')' contains=@cmakeParenCode,cmakeParenError

syn case ignore
" This is just matching the first line of an if, not the entire thing.
syn region cmakeCondRegion 
      \ matchgroup=cmakeConditional start='elseif' start='if' 
      \ matchgroup=NONE end=')' 
      \ contains=cmakeOperator,@cmakeParenCode
syn case match

""""""""""""""""""""""""
" Functions and Macros "
""""""""""""""""""""""""

" We must not consume the lparen -- it's needed for regions later.  Submatch
" means we don't highlight the extra whitespaces.
syn match cmakeFuncDefineName /[a-zA-Z_0-9]\+/ contained
syn match cmakeFuncDefineNameMatch /(\(\s|\n\)*[a-zA-Z_0-9]\+/ms=s+1 contained contains=cmakeFuncDefineName

syn case ignore
syn region cmakeDefineRegion
      \ matchgroup=cmakeFuncDefine start='macro' start='function'
      \ matchgroup=NONE end=')' 
      \ contains=cmakeFuncDefineNameMatch
syn case match

""""""""""""""""""""""""""""
" Special Function Regions "
""""""""""""""""""""""""""""

" A bit of an experiment.  More could be added in the same manner at will until
" you run out of patience or CPU time.

if exists('cmake_extra_predefs')
  syn keyword cmakeMessageFunctionArgs STATUS FATAL_ERROR contained

  " TODO:
  "   How might I specify precisely, and then report badnesses?
  syn region cmakeMessageFunctionRegion
        \ matchgroup=cmakePredefFunction start='message' matchgroup=NONE end=')' 
        \ contains=cmakeString,cmakeSubstitution,cmakeMessageFunctionArgs
end

""""""""""""""""""""""""""
" Error Checking Regions "
""""""""""""""""""""""""""

" Attempting to match each recursive part of the cmake file.  Since contains=
" turns off transparent (or so it seems), we need to use the TOP rule, which
" functions to contain all top-level rules.

if exists('cmake_ending_errors')
  syn case ignore

  " This sort of works, but lone end macro/functions aren't marked as errors.
  syn region cmakeFuncCheckRegion fold transparent
        \ start='function' end='endfunction'
        \ matchgroup=cmakeEndingError end='endmacro'
  syn region cmakeMacroCheckRegion fold transparent
        \ start='macro' end='endmacro'
        \ matchgroup=cmakeEndingError end='endfunction'

  " TODO:
  "   None of this works properly.  Some errors are reported; some are not.
  "   Maybe precedence problems?

  " I'm sure I've got this wrong, but it seems that if you specify the correct
  " ending of the region, it won't get matched by the end= of the region, even
  " though keepend is on.  Perhaps it's to do with precedence and using syn match
  " would work?

  " syn keyword cmakeMacroEndingError     ENDFOREACH ENDWHILE ENDFUNCTION ENDIF contained
  " syn keyword cmakeFunctionEndingError  ENDFOREACH ENDWHILE ENDMACRO ENDIF contained
  " syn keyword cmakeIfEndingError        ENDFOREACH ENDWHILE ENDFUNCTION ENDMACRO contained
  " syn keyword cmakeWhileEndingError     ENDFOREACH ENDMACRO ENDFUNCTION ENDIF contained
  " syn keyword cmakeForeachEndingError   ENDWHILE ENDMACRO ENDFUNCTION ENDIF contained

  " This is necessary so I can write TOP + others, instead of TOP - others.  The
  " latter is what happens when you specify groups after TOP.
  syn cluster cmakeEverythingButMacros contains=TOP,cmakeMacroCheckRegion,cmakeFuncCheckRegion

  " Here is one try:
  "
  " syn region cmakeForeachCheckRegion transparent 
  "       \ start='foreach' end='endforeach' 
  "       \ matchgroup=cmakeEndingError
  "       \   end='endmacro' end='endwhile' end='endif' end='endfunction'
  "       \ contains=@cmakeEverythingButMacros
  " syn region cmakeIfCheckRegion transparent 
  "       \ start='if' skip='\(else\)|\(elseif\)' end='endif' 
  "       \ matchgroup=cmakeEndingError
  "       \   end='endmacro' end='endwhile' end='endforeach' end='endfunction'
  "       \ contains=@cmakeEverythingButMacros
  " syn region cmakeWhileCheckRegion transparent 
  "       \ start='while' end='endwhile'
  "       \ matchgroup=cmakeEndingError
  "       \   end='endmacro' end='endforeach' end='endif' end='endfunction'
  "       \ contains=@cmakeEverythingButMacros

  " This method doesn't work either:
  "
  " syn region cmakeIfCheckRegion transparent
  "       \ start='if' skip='\(else\)|\(elseif\)' end='endif' 
  "       \ contains=@cmakeEverythingButMacros,cmakeIfEndingError
  " syn region cmakeForeachCheckRegion transparent
  "       \ start='foreach' end='endforeach' 
  "       \ contains=@cmakeEverythingButMacros,cmakeForeachEndingError
  " syn region cmakeWhileCheckRegion transparent
  "       \ start='while' end='endwhile'
  "       \ contains=@cmakeEverythingButMacros,cmakeWhileEndingError
  syn case match
else
  syn case ignore
  syn region cmakeFuncFoldRegion  transparent fold start='function' end='endfunction'
  syn region cmakeMacroFoldRegion transparent fold start='macro'    end='endmacro'
  syn case match
end

""""""""""""""""""""""""""""""""""
" Optional trailing space errors "
""""""""""""""""""""""""""""""""""

if exists("cmake_space_errors")
  if ! exists("cmake_no_trail_space_error")
    syn match cmakeSpaceError display excludenl "\s\+$"
  endif 
  if ! exists("cmake_no_tab_space_error")
    syn match cmakeSpaceError display " \+\t"me=e-1
  endif
endif

"""""""""""""""""""
" Colour defaults "
"""""""""""""""""""

hi def link cmakeParenError       cmakeError
hi def link cmakeCharError        cmakeError
hi def link cmakeSpaceError       cmakeError
hi def link cmakeError            Error

hi def link cmakeComment          Comment
hi def link cmakeTodo             Todo

hi def link cmakeEscape           Special
hi def link cmakeString           String
hi def link cmakeSubstitution     Define

hi def link cmakeEnvironmentSet   cmakeEnvironment
hi def link cmakeEnvironmentSub   cmakeEnvironment
hi def link cmakeEnvironment      Special

" Artistic license?  Struct is normally dark and that looks better since we use
" the define colours eveywhere else.
hi def link cmakeFuncDefine       Structure
hi def link cmakeFuncDefineName   Identifier
hi def link cmakePredefFunction   Define
hi def link cmakeUserFunctionCall Identifier

hi def link cmakeConditional      Conditional
hi def link cmakeRepeat           Repeat

hi def link cmakeConstant          Constant
hi def link cmakeOperator          Operator
hi def link cmakeStatementFunction Operator

if exists('cmake_ending_errors')
  hi def link cmakeMacroEndingError     cmakeEndingError
  hi def link cmakeFunctionEndingError  cmakeEndingError
  hi def link cmakeIfEndingError        cmakeEndingError
  hi def link cmakeWhileEndingErrors    cmakeEndingError
  hi def link cmakeForeachEndingErrors  cmakeEndingError
  hi def link cmakeEndingError          cmakeError
endif

if exists('cmake_extra_predefs')
  hi def link cmakeMessageFunctionArg cmakeFunctionArg

  hi def link cmakeFunctionArg Special
end

" Restore line continuation settings.
let &cpo = s:cpo_save
unlet s:cpo_save

let b:current_syntax = "cmake"
