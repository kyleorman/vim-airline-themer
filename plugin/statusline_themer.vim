" plugin/statusline_themer.vim

if exists('g:loaded_statusline_themer')
  finish
endif
let g:loaded_statusline_themer = 1

" Default settings
if !exists('g:statusline_themer_dirs')
  let g:statusline_themer_dirs = [
        \ '~/.vim',
        \ '/usr/share/vim/vimfiles',
        \ expand('~/.vim/plugged/vim-airline-themes/autoload/airline/themes'),
        \ expand('~/.local/share/nvim/plugged/vim-airline-themes/autoload/airline/themes'),
        \ ]
endif

if !exists('g:statusline_themer_silent')
  let g:statusline_themer_silent = 0
endif

if !exists('g:statusline_themer_disable_keybindings')
  let g:statusline_themer_disable_keybindings = 0
endif

if !exists('g:statusline_themer_pywal_update_interval')
  let g:statusline_themer_pywal_update_interval = 5000  " in milliseconds
endif

if !exists('g:statusline_themer_mode')
  let g:statusline_themer_mode = 'manual'  " Options: 'manual', 'pywal'
endif

" Defer the initialization until Vim has finished loading
augroup StatuslineThemerInit
  autocmd!
  autocmd VimEnter * call statusline_themer#init()
augroup END

" Define commands
command! StatuslineThemeSelect call statusline_themer#theme_select()
command! StatuslineSaveTheme call statusline_themer#save_theme()
command! StatuslinePywalMode call statusline_themer#toggle_pywal_mode()
command! StatuslineApplyPywal call statusline_themer#apply_pywal()

" Keybindings
if !g:statusline_themer_disable_keybindings
  nnoremap <silent> <leader>at :StatuslineThemeSelect<CR>
  nnoremap <silent> <leader>as :StatuslineSaveTheme<CR>
  nnoremap <silent> <leader>am :StatuslinePywalMode<CR>
  nnoremap <silent> <leader>ap :StatuslineApplyPywal<CR>
endif
