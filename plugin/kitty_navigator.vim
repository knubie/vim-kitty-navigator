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
  let pw = get(g:, 'kitty_navigator_password', 0)
  let pw_s = pw != "" ? '--password="' . pw . '" ' : ''
  let cmd = 'kitty @ ' . pw_s . a:args
  return system(cmd)
endfunction

let s:kitty_is_last_pane = 0

augroup kitty_navigator
  au!
  autocmd WinEnter * let s:kitty_is_last_pane = 0
augroup END

function! s:KittyIsInStackLayout()
  let layout = s:KittyCommand('kitten get_layout.py')
  return layout =~ 'stack'
endfunction

function! s:KittyAwareNavigate(direction)
  let nr = winnr()
  let kitty_last_pane = (a:direction == 'p' && s:kitty_is_last_pane)
  if !kitty_last_pane
    call s:VimNavigate(a:direction)
  endif
  let at_tab_page_edge = (nr == winnr())

  let kitty_is_in_stack_layout = s:KittyIsInStackLayout()
  let stack_layout_enabled = get(g:, 'kitty_navigator_enable_stack_layout', 0)

  let can_navigate_in_layout = !kitty_is_in_stack_layout || stack_layout_enabled 
  

  if (kitty_last_pane || at_tab_page_edge) && can_navigate_in_layout 
    let mappings = {
    \   "h": "left",
    \   "j": "bottom",
    \   "k": "top",
    \   "l": "right"
    \ }
    let args = 'focus-window --match neighbor:' . mappings[a:direction]
    silent call s:KittyCommand(args)
    let s:kitty_is_last_pane = 1
  else
    let s:kitty_is_last_pane = 0
  endif
endfunction
