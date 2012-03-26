" autoload/ant.vim
" Author: Tim Horton

if exists('g:autoloaded_ant') || &cp
  finish
endif
let g:autoloaded_ant = 1

" {{{ public methods

function! ant#init(antroot)
  let b:antroot = a:antroot
  call s:initMake()
  call s:initTargets()
endfunction

function! ant#reload()
  call delete(s:targetFile())
  let b:targets = []
  call ant#init(b:antroot)
endfunction

function! ant#run(bang, ...)
  let cwd = getcwd()
  exe 'chdir ' . b:antroot
  exe 'make' . (a:bang ? '!' : '') . ' ' . join(a:000, ' ')
  exe 'chdir ' . cwd
endfunction

" }}}
" {{{ helpers

function! s:antcomplete(A, L, P)
  return filter(copy(b:targets), " match('".a:L."', v:val) < 0 && match(v:val, '^".a:A."') >= 0 ")
endfunction

function! s:initMake()
  set efm=%A%*[\ ][javac]\ %f:%l:\ %m,%-Z%*[\ ][javac]\ %p^,%-C%.%#
  setlocal makeprg=ant
endfunction

" TODO: make cross platform
function! s:targetFile()
  return '/tmp/.ant_' . substitute(fnamemodify(b:antroot, ':t'), '\W', '', 'g') . '_targets'
endfunction

function! s:initTargets()
  let b:targets = []
  if filereadable(s:targetFile())
    let b:targets = readfile(s:targetFile())
  else
    let b:targets = s:getTargets()
    call sort(b:targets)
    call writefile(b:targets, s:targetFile())
  endif

  command! -buffer -bar -bang -nargs=+ -complete=customlist,s:antcomplete Ant :call ant#run(<bang>0, <f-args>)
  command! -buffer AntReload   :call ant#reload()
  for c in [ "E", "T", "S", "V" ]
    exe 'command! -buffer -bang -nargs=1 -complete=customlist,s:fileComplete AntRel'.c.'  :call s:editFile(<bang>0, "'.c.'", <f-args>)'
  endfor
endfunction

function! s:editFile(bang, cmd, file)
  let cmd = s:cmdLookup(a:cmd)
  if a:bang
    let cmd .= '!'
  endif
  echo cmd
  exe cmd . ' ' . b:antroot . '/' . a:file
endfunction

function! s:cmdLookup(c)
  if      a:c == 'E' | return 'edit'
  elseif a:c == 'S' | return 'split'
  elseif a:c == 'V' | return 'vsplit'
  elseif a:c == 'T' | return 'tabnew'
  else | return 'edit'
  endif
endfunction

function! s:fileComplete(A,L,P)
  return map(split(globpath(b:antroot, a:A.'*'), "\n"), 'substitute(v:val, "'.b:antroot.'/", "", "")')
endfun

function! s:getTargets()
    return keys(s:buildFile(s:projectHelp()))
endfunction

function! s:projectHelp()
  let targets = {}
  let cwd = getcwd()
  exe 'chdir ' . b:antroot
  let lines = split(system('ant -p'), '\n')
  for line in lines
    let m = matchlist(line, '^\s\+\(\w*\)\s\+.*')
    if len(m) >= 1 && !empty(m[1])
      let targets[m[1]] = ''
    endif
  endfor
  exe 'chdir ' . cwd
  return targets
endfunction

function! s:buildFile(targets)
  let targets = a:targets
  let lines = readfile(b:antroot . '/build.xml')
  for line in lines
    let l = matchlist(line, '\s*<target.*name=\"\(\w\{-}\)\".*')
    if len(l) > 1 && !empty(l[1])
      let targets[l[1]] = ''
    endif
  endfor
  return targets
endfunction

function! s:toProper(s)
  return substitute(a:s, '\(.*\)', '\u\1', '')
endfunction

" }}}

" vim:set ft=vim sw=2 ts=2 et fdm=marker:
