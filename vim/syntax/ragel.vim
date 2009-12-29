" Vim syntax file
"
" These variables are used:
"
" - ragel_lang
"
" Language: Ragel
" Author: Adrian Thurston (modified by James Webber)

if exists("b:current_syntax")
  finish
endif

" TODO:
"   Main problem is that C++ code *after* the state machine is highlighted
"   completely wrongly.  Identifiers seem to become operators or similar
"   (yellow) by default even outside of the machine spec.
"
"   It can't deal with it at all when you can't see the start of the machine.
"   Maybe this is the 
"
"   #define at the start of the file is matched as a comment?!
"
"   The character class match breaks everything, even though it's contained?!
"
"   It seems that a lot of contained stuff is being matched outside where it is
"   supposed to be contained... perhaps the C is using a CONTAINED,except ?

syn sync fromstart

" Load a sub-syntax into the rlSubLang group.
fun! RagelLoadLangSyntax(language_file)
  " Otherwise the file will not define anything.
  if exists("b:current_syntax")
    unlet b:current_syntax
  end

  " Look for a file in ~/.vim first.  Docs imply you don't need to do this, so
  " maybe I've got it wrong.
  let s:relative_file = expand("<sfile>:p:h" . a:language_file)

  if filereadable(s:relative_file)
    exec 'syn include @rlSubLang ' . s:relative_file
  else
    exec 'syn include @rlSubLang ' . "$VIMRUNTIME/syntax/" . a:language_file
  end
endfun

" Will this work for local files?
runtime! syntax/cpp.vim

call RagelLoadLangSyntax('cpp.vim')

" Identifiers
syntax match rlIdentifier "[a-zA-Z_][a-zA-Z_0-9]*" contained

" Inline code only
syntax keyword rlFsmType fpc fc fcurs fbuf fblen ftargs fstack contained
syntax keyword rlFsmKeyword fhold fgoto fcall fret fentry fnext fexec fbreak contained

syntax cluster rlItems contains=rlComment,rlLiteral,rlAugmentOps,rlOtherOps,rlKeywords,rlWrite,rlCodeCurly,rlCodeSemi,rlNumber,rlIdentifier,rlLabelColon,rlExprKeywords

syntax region rlMachineSpec1 matchgroup=rlBegin start="%%{" end="}%%" contains=@rlItems
syntax region rlMachineSpec2 matchgroup=rlBegin start="%%[^{]"rs=e-1 end="$" keepend contains=@rlItems
syntax region rlMachineSpec2 matchgroup=rlBegin start="%%$" end="$" keepend contains=@rlItems

" Comments
" TODO: 
"   this gets matched as a comment on the second line of a preproc directive at
"   the start of the file (i.e. not in the state machine), as in #define.
"   WTF?!?!?!
syntax match rlComment "#.*$" contained

" Literals
syntax match rlLiteral "'\(\\.\|[^'\\]\)*'[i]*"    contained
syntax match rlLiteral "\"\(\\.\|[^\"\\]\)*\"[i]*" contained
syntax match rlLiteral /\/\(\\.\|[^\/\\]\)*\/[i]*/ contained
" TODO: this breaks the C++ code, even though it's contained.  Wtf?!
" syntax match rlLiteral "\[\(\\.\|[^\]\\]\)*\]"     contained

" Numbers
syntax match rlNumber "[0-9][0-9]*"               contained
syntax match rlNumber "0x[0-9a-fA-F][0-9a-fA-F]*" contained

" Operators
syntax match rlAugmentOps "[>$%@]"           contained
syntax match rlAugmentOps "<>\|<"            contained
syntax match rlAugmentOps "[>\<$%@][!\^/*~]" contained
syntax match rlAugmentOps "[>$%]?"           contained
syntax match rlAugmentOps "<>[!\^/*~]"       contained
syntax match rlAugmentOps "=>"               contained
syntax match rlOtherOps   "->"               contained

" TODO: these never get matched.
syntax match rlOtherOps   "<:"  contained
syntax match rlOtherOps   ":>"  contained
syntax match rlOtherOps   ":>>" contained

" Keywords
" FIXME: Enable the range keyword post 5.17.
" syntax keyword rlKeywords machine action context include range contained
syntax keyword rlKeywords     contained machine action context include import export prepush postpop
syntax keyword rlExprKeywords contained when inwhen outwhen err lerr eof from to

syntax match rlLabelColon "[a-zA-Z_][a-zA-Z_0-9]*[ \t]*:$" contained contains=rlLabel
syntax match rlLabelColon "[a-zA-Z_][a-zA-Z_0-9]*[ \t]*:[^=:>]"me=e-1 contained contains=rlLabel
syntax match rlLabel "[a-zA-Z_][a-zA-Z_0-9]*" contained

" All items that can go in a code block.
syntax cluster rlInlineItems 
      \ contains=rlIdentifier,rlFsmType,rlFsmKeyword,caseLabelColon,@rlSubCurly,@rlSubLang,

" Hack to get sub-brackets to work when there are multiple levels of braced
" code.  I think it's to do with how brackets are specified with/without keepend 
" in the sub-language.  This is recursive via. rlInlineItems.  If you don't do
" this then the first '}' is matched as the end of region.  There's probably a
" better way to do this.
syntax region rlSubCurly start='{' end='}' contained keepend contains=@rlInlineItems

" Blocks of code.
syntax region rlCodeCurly matchgroup=Operator start="{" end="}" contained contains=rlSubCurly,@rlInlineItems
syntax region rlCodeSemi matchgroup=Type contained keepend contains=@rlInlineItems
      \ start="\<alphtype\>" start="\<getkey\>" start="\<access\>" start="\<variable\>" 
      \ matchgroup=NONE end=";"

syntax region rlWrite matchgroup=Type start="\<write\>" matchgroup=NONE end="[;)]" contained contains=rlWriteKeywords,rlWriteOptions

syntax keyword rlWriteKeywords init data exec exports start error first_final contained
syntax keyword rlWriteOptions noerror nofinal noprefix noend nocs contained

"
" Sync at the start of machine specs.
"
" Match The ragel delimiters only if there quotes no ahead on the same line.
" On the open marker, use & to consume the leader.
syntax sync match ragelSyncPat grouphere NONE "^[^\'\"%]*%%{&^[^\'\"%]*"
syntax sync match ragelSyncPat grouphere NONE "^[^\'\"%]*%%[^{]&^[^\'\"%]*"
syntax sync match ragelSyncPat grouphere NONE "^[^\'\"]*}%%"

"
" Specifying Groups
"

hi link rlComment Comment
hi link rlNumber Number
hi link rlLiteral String
hi link rlAugmentOps Keyword
hi link rlExprKeywords Keyword
hi link rlWriteKeywords Keyword
hi link rlWriteOptions Keyword
hi link rlKeywords Type

hi link rlFsmType Type
hi link rlFsmKeyword Keyword
hi link rlLabel Label
hi link rlBegin Type
 
let b:current_syntax = "ragel"

