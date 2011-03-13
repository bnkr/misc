" Filetype detection.  It's necessary to do this in a separate file or stuff
" gets redetected, usually as conf.

if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  au! BufRead,BufNewFile *.rl setfiletype ragel
augroup END
