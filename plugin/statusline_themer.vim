" plugin/statusline_themer.vim

if exists('g:loaded_statusline_themer')
  finish
endif
let g:loaded_statusline_themer = 1

" Default settings with path handling for different plugin managers and locations
let g:statusline_themer_dirs = get(g:, 'statusline_themer_dirs', [
      \ '~/.vim/pack/plugins/start/vim-airline-themes/autoload/airline/themes'
      \ ])

" Core configuration options with sensible defaults
let g:statusline_themer_silent = get(g:, 'statusline_themer_silent', 0)
let g:statusline_themer_mode = get(g:, 'statusline_themer_mode', 'manual')
let g:statusline_themer_pywal_update_interval = get(g:, 'statusline_themer_pywal_update_interval', 5000)
let g:statusline_themer_tmuxline_save = get(g:, 'statusline_themer_tmuxline_save', 1)
let g:statusline_themer_disable_keybindings = get(g:, 'statusline_themer_disable_keybindings', 0)

" Ensure required dependencies
if !exists('g:loaded_airline')
  echohl ErrorMsg | echo "vim-statusline-themer requires vim-airline" | echohl None
  finish
endif

" Define user commands with proper completion
command! -nargs=? -complete=customlist,statusline_themer#complete_themes StatuslineThemeSelect call statusline_themer#select_theme(<f-args>)
command! -nargs=0 StatuslineSaveTheme call statusline_themer#save_theme()
command! -nargs=0 StatuslinePywalMode call statusline_themer#toggle_pywal_mode()
command! -nargs=0 StatuslineApplyPywal call statusline_themer#apply_pywal()
command! -nargs=0 StatuslineReload call statusline_themer#reload()

" Setup initialization and cleanup autocommands
augroup StatuslineThemerInit
  autocmd!
  " Initialize after Vim is fully loaded
  autocmd VimEnter * ++nested call statusline_themer#init()
  " Preserve theme after colorscheme changes, but only after initialization
  autocmd ColorScheme * if exists('g:statusline_themer_initialized') | call statusline_themer#preserve_theme() | endif
augroup END

augroup StatuslineThemerCleanup
  autocmd!
  autocmd VimLeave * call statusline_themer#cleanup()
augroup END

" Default keybindings unless disabled
if !g:statusline_themer_disable_keybindings
  nnoremap <silent> <leader>at :StatuslineThemeSelect<CR>
  nnoremap <silent> <leader>as :StatuslineSaveTheme<CR>
  nnoremap <silent> <leader>am :StatuslinePywalMode<CR>
  nnoremap <silent> <leader>ap :StatuslineApplyPywal<CR>
  nnoremap <silent> <leader>ar :StatuslineReload<CR>
endif
