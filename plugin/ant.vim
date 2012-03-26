" plugin/ant.vim - Interface between vim and ant
" Author: Tim Horton

if exists('g:loaded_ant') || &cp || v:version < 700 || !executable('ant')
  finish
endif

let g:loaded_ant = 1

function! s:listdir(dir)
  return split(expand(a:dir . '/*'))
endfunction

function! s:detect(filename)
  if a:filename == '/' | return 0 | endif
  if isdirectory(a:filename)
    let files = map(s:listdir(a:filename), "fnamemodify(v:val, ':t')")
    for file in files
      if file == "build.xml"
        return ant#init(a:filename)
      endif
    endfor
  endif
  return s:detect(fnamemodify(a:filename, ":h"))
endfunction

augroup antAppDetect
  autocmd!
  autocmd BufNewFile,BufRead * call s:detect(expand("<afile>:p"))
  autocmd VimEnter * if !exists("b:antroot") | call s:detect(getcwd()) | endif
augroup END

" vim:set ft=vim sw=2 ts=2 et fdm=marker:
