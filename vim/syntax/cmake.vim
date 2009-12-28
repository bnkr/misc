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

if exists("b:current_syntax")
  finish
endif

" Main Todo:
"
" - cmakeUserFunctionCall and cmakeFuncDefineName match too much.  I want to
"   stop at the end of the identifier.  Do I seriously need a sub-match just for
"   that?
"
" - error checking regions aren't done.
"
" - Colours aren't that nice.  I think I prefer function calls as normal, and
"   any other identifier as identifiers.
"
" - Predefined vars (or at least system vars).  Colour of Define I suppose;
"   constant could be better as it is different from the substitutions.

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
syn match cmakeFunctionCallMatch /[a-zA-Z0-9_]\+\(\s\|\n\)*(/me=e-1 contains=cmakePredefFunction,cmakeUserFunctionCall

" An uncontained match for bad characters; i.e. those which aren't allowed
" outside paren'ed code.
syn match cmakeCharError /[;.]/

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

""""""""""""""""""""""""""""""
" Parenthesised code regions "
""""""""""""""""""""""""""""""

" Alias for everthing that can go in parens, but not including things like
" operators or special arguments.
syn cluster cmakeParenCode contains=cmakeSubstitution,cmakeString,cmakeComment,cmakeConstant

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
"
" TODO: how do you use TOP the subcheckregions?  Maybe containedin?

" syn cluster cmakeSubCheckRegions contains=cmakeForeachCheckRegion,cmakeWhileCheckRegion,cmakeIfCheckRegion
" syn region cmakeFuncCheckRegion transparent keepend fold contains=@cmakeSubCheckRegions
"       \ start='function' end='endfunction' 
" syn region cmakeMacroCheckRegion transparent keepend fold contains=cmakeMacroCheckError
"       \ start='macro' end='endmacro'  
" syn region cmakeForeachCheckRegion transparent keepend start='foreach' end='endforeach' contains=@cmakeSubCheckRegions
" syn region cmakeWhileCheckRegion transparent keepend start='while' end='endwhile' contains=@cmakeSubCheckRegions
" syn region cmakeIfCheckRegion transparent keepend start='if' skip='\(else\)|\(elseif\)' end='endif' contains=@cmakeSubCheckRegions

syn region cmakeFuncCheckRegion  transparent fold start='function' end='endfunction'
syn region cmakeMacroCheckRegion transparent fold start='macro'    end='endmacro'

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

" Artistic license?  Struct is normally dark and that looks better since we use
" the define colours eveywhere else.
hi def link cmakeFuncDefine       Structure
hi def link cmakeFuncDefineName   Identifier
hi def link cmakePredefFunction   Define
hi def link cmakeUserFunctionCall Identifier

hi def link cmakeConditional      Conditional
hi def link cmakeRepeat           Repeat

hi def link cmakeConstant         Constant
hi def link cmakeOperator         Operator

if exists('cmake_extra_predefs')
  hi def link cmakeMessageFunctionArg cmakeFunctionArg

  hi def link cmakeFunctionArg Special
end

" Restore line continuation settings.
let &cpo = s:cpo_save
unlet s:cpo_save

let b:current_syntax = "cmake"
