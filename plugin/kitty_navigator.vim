" Maps <C-h/j/k/l> to switch vim splits in the given direction. If there are
" no more windows in that direction, forwards the operation to kitty.

if exists("g:loaded_kitty_navigator") || &cp || v:version < 700
  finish
endif
let g:loaded_kitty_navigator = 1

function! s:VimNavigate(direction)
  try
    execute 'wincmd ' . a:direction
  catch
    echohl ErrorMsg | echo 'E11: Invalid in command-line window; <CR> executes, CTRL-C quits: wincmd k' | echohl None
  endtry
endfunction

if !get(g:, 'kitty_navigator_no_mappings', 0)
  nnoremap <silent> <c-h> :KittyNavigateLeft<cr>
  nnoremap <silent> <c-j> :KittyNavigateDown<cr>
  nnoremap <silent> <c-k> :KittyNavigateUp<cr>
  nnoremap <silent> <c-l> :KittyNavigateRight<cr>
endif

command! KittyNavigateLeft     call s:KittyAwareNavigate('h')
command! KittyNavigateDown     call s:KittyAwareNavigate('j')
command! KittyNavigateUp       call s:KittyAwareNavigate('k')
command! KittyNavigateRight    call s:KittyAwareNavigate('l')

function! s:KittyCommand(args)
  let cmd = 'kitty @ ' . a:args
  return system(cmd)
endfunction

let s:kitty_is_last_pane = 0

augroup kitty_navigator
  au!
  autocmd WinEnter * let s:kitty_is_last_pane = 0
augroup END

if !get(g:, 'kitty_navigator_installation_path')
  let g:kitty_navigator_installation_path = './vim-kitty-navigator'
endif

" Function: s:path_join(pathparts, {path_separator}) {{{3
function! s:path_join(pathparts, ...) abort
  let sep
        \ = (a:0) == 0                       ? '/'
        \ : type(a:1)==type(0) && (a:1) == 0 ? '/'
        \ : (a:1) == 1                       ? '\'
        \ : (a:1) =~ 'shellslash\|ssl'       ? (&ssl ? '\' : '/')
        \ :                                    (a:1)
  return join(a:pathparts, sep)
endfunction

function! s:KittyAwareNavigate(direction)
  let nr = winnr()
  let kitty_last_pane = (a:direction == 'p' && s:kitty_is_last_pane)
  if !kitty_last_pane
    call s:VimNavigate(a:direction)
  endif
  let at_tab_page_edge = (nr == winnr())

  if kitty_last_pane || at_tab_page_edge
    let mappings = {
    \   "h": "left",
    \   "j": "bottom",
    \   "k": "top",
    \   "l": "right"
    \ }
    let args = 'kitten ' . s:path_join([get(g:, 'kitty_navigator_installation_path'), 'neighboring_window.py']) . ' ' . mappings[a:direction]
    silent call s:KittyCommand(args)
    let s:kitty_is_last_pane = 1
  else
    let s:kitty_is_last_pane = 0
  endif
endfunction
