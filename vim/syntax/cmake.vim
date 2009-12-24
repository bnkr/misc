" =============================================================================
"
"   Program:   CMake - Cross-Platform Makefile Generator
"   Module:    $RCSfile: cmake-syntax.vim,v $
"   Language:  VIM
"
" =============================================================================

" Vim syntax file
"
" This file has been modified by James Webber.  Last change December 2009.
" Responds to the normal space_error variables:
"
" - cmake_space_error
"   - cmake_no_trail_space_error 
"   - cmake_no_tab_space_error
" - cmake_no_capital_variables -- turn of matching upper-case only identifiers
"   as special.
" - cmake_fast_predefines -- use keywords for pre-defined function highlighting.
"   This should be faster, but it will match 'list' in 'set(list'.
"
" The following message is preserved from the original.
"
" Language:     CMake
" Author:       Andy Cedilnik <andy.cedilnik@kitware.com>
" Maintainer:   Karthik Krishnan <karthik.krishnan@kitware.com>
"
" Licence:      The CMake license applies to this file. See
"               http://www.cmake.org/HTML/Copyright.html
"               This implies that distribution with Vim is allowed

" Main todo:
"
" TODO:
"
" - match the name of the macro in a diferent color (cmakeDefinedName).
" - indent of "x\n(\n)" doesn't work.
" - matching a function call with missing terminating bracket is really hard!
"   - note: the if-region at least succeeds in screwing up the highlighting if
"     you forget the bracket maybe we can deal with that?
" - un-match cmake function keywords in a function call (e.g. set(list gets
"   highlighted wronly).  
"   - The solution is to syn match them all and then match identifiers in a
"     (...) region to override them.
" - the capital letter thing should only happen inside function caslls, not ifs
"   becasue they conflict with cmake constants.  In functions they normally mean
"   named param arguments.

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Line continuations will be used.
let s:cpo_save = &cpo
set cpo-=C

" Things that can be used in an if statement.  NB: these are case sensitive.
syn keyword cmakeOperator contained
      \ IS_ABSOLUTE IS_DIRECTORY EXISTS
      \ IS_NEWER_THAN 
      \ DEFINED 
      \ COMMAND 
      \ AND OR NOT
      \ STREQUAL STRGREATER STRLESS MATCHES
      \ EQUAL GREATER LESS
      \ VERSION_LESS VERSION_GREATER VERSION_EQUAL

syn keyword cmakeConstant
      \ TRUE FALSE ON OFF YES NO

" Still case sensitive!
syn keyword cmakeTodo contained TODO FIXME XXX

if ! exists('cmake_no_capital_variables')
  " again, needs to be up here so it's case sensitive!
  syn match cmakeCapitalVariable    /\<\([A-Z][A-Z_0-9]*\)\>/
endif

" Bit of a hack.
syn match cmakePredefinedVariable /CMAKE_[A-Z_]\+/

syn match cmakeNumber /[0-9]+/

syn case ignore

syn keyword cmakeStatement
      \ ENDIF FOREACH WHILE ENDFOREACH ENDWHILE ELSE

" Pre-defined functions/macros.
" TODO: I could use nextgroup= to check arguments to cmake functions only.
syn keyword cmakePredefFunction
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
      \ VTK_WRAP_JAVA VTK_WRAP_PYTHON VTK_WRAP_TCL WRITE_FILE GET_PROPERTY

syn keyword cmakeDeprecated
      \ ABSTRACT_FILES BUILD_NAME SOURCE_FILES SOURCE_FILES_REMOVE 
      \ VTK_MAKE_INSTANTIATOR VTK_WRAP_JAVA 
      \ VTK_WRAP_PYTHON VTK_WRAP_TCL WRAP_EXCLUDE_FILES


" Don't tell me you never accidentally do this :).  Note: this will appear as an
" error in function argument lists when technically it's allowed.
syn match cmakeError /[;}{]/


" Unterminated variable substitution.
syn match cmakeError /\${[^}]*$/
" TODO: 
"   Mathing broken brackets:
"
"
"   this matches while we're typing making a whole load of red show up
"   when we didn't actually make a mistake yet!
"
"     syn match cmakeError /(\([^)"]\|\n\)*(/
"
"   breaks everything even though both are contained?!.
"
"     syn match cmakeBracketError /[()]/ contained
"     syn region cmakeBracketRegion start='(' end=')' contains=cmakeString,cmakeBracketError
"
" TODO:
"    Breks everything not in a fold.
"
"      syn match cmakeError /[()]/
"
" TODO: doesn't work: keyword priority, perhaps?
syn region cmakeBracketRegion start='(' end=')' transparent keepend contains=ALLBUT,cmakePredefFunction

syn region cmakeComment start="#" end="$" contains=cmakeTodo,@Spell

syn match  cmakeEscaped /\(\\\\\|\\"\|\\n\|\\t\)/   contained
" A different rule because regex will be Special and so will normal escaped.
syn match  cmakeRegexEscaped /\(\\\\\|\\"\|\\n\|\\t\)/   contained

" This is actually not great because they go directly in strings; you end up
" with the wrong stuff highlighted.
syn region cmakeRegex start=/\[/ skip=/\\]/ end=/]/ contained oneline contains=cmakeVariableValue,cmakeRegexEscaped
syn region cmakeVariableValue start=/\${/ end=/}/  oneline contains=cmakePredefinedVariable,cmakeSystemVariable
syn region cmakeEnvironment start=/\$ENV{/ end=/}/ oneline contains=cmakeVariableValue

syn region cmakeString contains=cmakeRegex,cmakeVariableValue,cmakeEscaped
      \ start=+"+ skip='\\"' end=/"/ 

syn keyword cmakeSystemVariable
      \ WIN32 UNIX APPLE CYGWIN BORLAND MINGW MSVC MSVC_IDE MSVC60 
      \ MSVC70 MSVC71 MSVC80 MSVC90

" It's user-defined because they predefined keywords always override this.  This
" must be before the folds or it overrides them.  This must be before the if
" region.
syn match cmakeUserFuncCall /[a-zA-Z][a-z0-9A-Z_]*(/me=e-1

" Just if (...) so we can match the special operators that go in there.
syn region cmakeIfRegion transparent keepend
      \ matchgroup=cmakeStatement start='if' start="elseif" 
      \ matchgroup=NONE end=')'
      \ contains=cmakeOperator,cmakeString,cmakeVariableValue,cmakeEnvironment,cmakePredefinedVariable,
      \          cmakeSystemVariable,cmakeConstant,cmakeCapitalVariable

" I can't use ALL because I end up geting things like the error
" expressions in there
syn cluster cmakeMostThings 
      \ contains=cmakeOperator,cmakeString,cmakeVariableValue,cmakeEnvironment,
      \ cmakePredefinedVariable, cmakeSystemVariable,cmakeConstant,
      \ cmakeCapitalVariable,cmakeDefineArgs,cmakeUserFuncCall,cmakeStatement,
      \ cmakeComment,cmakeIfRegion,cmakePredefFunction

" TODO: folding won't work well unless we force the synclines to be better.
syn region cmakeFunctionDefRegion transparent fold matchgroup=cmakeFunctionDef
      \ start=+^function+ start=+\sfunction+ms=s+1 
      \ end='endfunction' matchgroup=cmakeError end='endmacro'
      \ contains=@cmakeMostThings

syn region cmakeMacroRegion transparent fold matchgroup=cmakeFunctionDef
      \ start=+^macro+ start=+\smacro+ms=s+1 
      \ end='endmacro' matchgroup=cmakeError end='endfunction'
      \ contains=@cmakeMostThings

" Ensures they are matched whether there is a region match for them or not.
syn match cmakeFunctionDef /ENDMACRO/
syn match cmakeFunctionDef /ENDFUNCTION/

if exists("cmake_space_errors")
  if ! exists("cmake_no_trail_space_error")
    syn match cmakeSpaceError display excludenl "\s\+$"
  endif 
  if ! exists("cmake_no_tab_space_error")
    syn match cmakeSpaceError display " \+\t"me=e-1
  endif
endif

hi def link cmakeFunctionEndError cmakeError
hi def link cmakeMacroEndError    cmakeError
hi def link cmakeDefineArgsError  cmakeError
hi def link cmakeBracketError     cmakeError
hi def link cmakeError            Error

hi def link cmakeComment          Comment
hi def link cmakeString           String
hi def link cmakeNumber           String
hi def link cmakeStatement        Statement

hi def link cmakeOperator            Operator
hi def link cmakeTodo                Todo
hi def link cmakeVariableValue       Type

hi def link cmakePredefFunction      Define
hi def link cmakeDefinedName         Define

hi def link cmakeUserFuncCall        Function
hi def link cmakeFunctionDef         Structure

hi def link cmakeRegex               Special
hi def link cmakeEscaped             Special
hi def link cmakeEnvironment         Special

hi def link cmakeCapitalVariable     Constant
hi def link cmakePredefinedVariable  Constant
hi def link cmakeConstant            Constant
hi def link cmakeSystemVariable      Constant


" Restore line continuation settings.
let &cpo = s:cpo_save
unlet s:cpo_save

let b:current_syntax = "cmake"
