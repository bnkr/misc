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
" Vars:
"
" - cmake_space_error
"   - cmake_no_trail_space_error 
"   - cmake_no_tab_space_error

if exists("b:current_syntax")
  finish
endif

" Line continuations will be used.
let s:cpo_save = &cpo
set cpo-=C

"""""""""""""""
" Basic stuff "
"""""""""""""""
syn keyword cmakeTodo TODO FIXME XXX
syn match cmakeComment /#.*$/ contains=cmakeTodo,@Spell
" TODO: there are more substitutions
syn match cmakeEscape /\\[nrtb\\"]/ contained
" TODO: will the skip be matched as an escape?
syn region cmakeString start='"' skip='\\"' end='"' contained contains=cmakeSubstitution,cmakeEscape

" This is recursive, so it has to be a region.  Note that this one doesn't
" keepend because the sub-substitution should consume the close bracket.
syn region cmakeSubstitution start='\${' end='}' oneline contains=cmakeSubstitution

" Non-contained and with a low precedence to be the default match.
"
" TODO: 
"   how do I stop the match at the end of the identifier -- I don't want to
"   match the whitespaces or lparen
syn match cmakeUserFunctionCall /[a-zA-Z0-9_]\+\(\s\|\n\)*(/me=e-1 contains=cmakePredefFunction,cmakeOtherStatement

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

" This is used because I don't do a full region match for these -- only the
" actual if(...) is handled.  The begin statements will be matchgroups in a
" region start=.
syn keyword cmakeStatement
      \ ENDFOREACH ENDIF ENDWHILE ELSE
syn case match

" TODO: 
"   choice: match predefined vars as global keywords, or put them only in
"   parenthesised code?

""""""""""""""""""""""""""""""
" Parenthesised code regions "
""""""""""""""""""""""""""""""

" Alias for everthing that can go in parens, but not including things like
" operators or special arguments.
syn cluster cmakeParenCode contains=cmakeSubstitution,cmakeString,cmakeComment


" The basic function parameters.
" TODO: 
"   I need to do something special with the colors here or the code is just too
"   spartan.  I guess I either do the capital-letter vars a different colour, or
"   do all vars a different colour.
syn region cmakeParenRegion start='(' end=')' contains=@cmakeParenCode

syn case ignore
" This is just matching the first line of an if.
syn region cmakeCondRegion 
      \ matchgroup=cmakeStatement start='elseif' start='if' 
      \ matchgroup=NONE end=')' 
      \ contains=cmakeOperator,@cmakeParenCode
syn case match

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

hi def link cmakeStatement        Statement
hi def link cmakeTodo             Todo
hi def link cmakeString           String
hi def link cmakeEscape           Special
hi def link cmakeComment          Comment
hi def link cmakeUserFunctionCall Identifier
hi def link cmakeOperator         Operator
hi def link cmakeSubstitution     Define
hi def link cmakePredefFunction   Define


" Restore line continuation settings.
let &cpo = s:cpo_save
unlet s:cpo_save

let b:current_syntax = "cmake"
