" autoload/statusline_themer.vim

if exists('g:loaded_statusline_themer_autoload')
  finish
endif
let g:loaded_statusline_themer_autoload = 1

" Initialization function called on VimEnter
function! statusline_themer#init() abort
  if g:statusline_themer_mode ==# 'pywal'
    call statusline_themer#start_pywal_monitor()
  else
    call statusline_themer#load_saved_theme()
  endif
endfunction

" Function to search for available Airline themes recursively
function! statusline_themer#find_themes() abort
  let l:themes = []
  for dir in g:statusline_themer_dirs
    let l:dir = expand(dir, 1)
    if isdirectory(l:dir)
      " Recursively search for theme files in 'themes' subdirectories
      let l:found = globpath(l:dir, '**/themes/*.vim', 0, 1)
      for file in l:found
        let l:theme_name = fnamemodify(fnamemodify(file, ':t'), ':r')
        call add(l:themes, l:theme_name)
      endfor
    endif
  endfor
  return uniq(sort(l:themes))
endfunction

" Function to apply a selected theme to Airline
function! statusline_themer#apply_theme(theme) abort
  if a:theme ==# 'pywal'
    call statusline_themer#apply_pywal_theme()
  else
    let g:airline_theme = a:theme
    if exists('*airline#load_theme')
      call airline#load_theme()
      if !g:statusline_themer_silent
        echo "Statusline theme set to: " . a:theme
      endif
    else
      echo "Airline is not installed or outdated."
    endif
  endif
endfunction

" Function to open FZF theme selector
function! statusline_themer#theme_select() abort
  let l:themes = statusline_themer#find_themes()
  if empty(l:themes)
    echo "No statusline themes found."
    return
  endif

  let l:fzf_options = '--prompt="Statusline Theme> "'
  if has('nvim')
    let l:fzf_options .= ' --layout=reverse'
  endif

  call fzf#run(fzf#wrap({
        \ 'source': l:themes,
        \ 'sink':   function('statusline_themer#apply_theme'),
        \ 'options': l:fzf_options,
        \ }))
endfunction

" Function to load the saved theme from XDG config
function! statusline_themer#load_saved_theme() abort
  let l:config_file = statusline_themer#xdg_config_dir() . '/theme'
  if filereadable(l:config_file)
    let l:saved_theme = trim(readfile(l:config_file)[0])
    if !empty(l:saved_theme)
      call statusline_themer#apply_theme(l:saved_theme)
    endif
  endif
endfunction

" Function to save the current theme to XDG config
function! statusline_themer#save_theme() abort
  let l:config_dir = statusline_themer#xdg_config_dir()
  if !isdirectory(l:config_dir)
    call mkdir(l:config_dir, 'p')
  endif
  let l:config_file = l:config_dir . '/theme'
  call writefile([g:airline_theme], l:config_file)
  if !g:statusline_themer_silent
    echo "Statusline theme saved: " . g:airline_theme
  endif
endfunction

" Function to get the XDG config directory
function! statusline_themer#xdg_config_dir() abort
  let l:xdg_config_home = has('unix') ? $XDG_CONFIG_HOME : ''
  if empty(l:xdg_config_home)
    let l:xdg_config_home = has('unix') ? expand('~/.config') : expand('$HOME/_vim_config')
  endif
  return l:xdg_config_home . '/vim-statusline-themer'
endfunction

" Function to check for Pywal updates
function! statusline_themer#pywal_update(timer) abort
  let l:colors_json = expand('~/.cache/wal/colors.json')
  if !filereadable(l:colors_json)
    echo "Pywal colors.json not found."
    return
  endif

  let l:current_mtime = getftime(l:colors_json)
  if l:current_mtime !=# g:statusline_themer_pywal_last_mtime
    let g:statusline_themer_pywal_last_mtime = l:current_mtime
    call statusline_themer#apply_pywal_theme()
  endif
endfunction

" Function to apply Pywal colors to Airline
" Function to apply Pywal colors to Airline
function! statusline_themer#apply_pywal_theme() abort
  if !exists('*json_decode')
    echo "Your Vim does not support JSON decoding. Pywal integration requires Vim 8.1+ with +json."
    return
  endif

  let l:colors_json = expand('~/.cache/wal/colors.json')
  if !filereadable(l:colors_json)
    echo "Pywal colors.json not found."
    return
  endif

  let l:colors_content = join(readfile(l:colors_json), '')
  let l:colors = json_decode(l:colors_content)

  if empty(l:colors)
    echo "Failed to parse colors.json."
    return
  endif

  " Map Pywal colors to Airline theme
  let s:palette = {}

  " Helper function to create color mappings
  function! s:color(fg_hex, bg_hex, style) abort
    return {
          \ 'gui':   a:style,
          \ 'cterm': a:style,
          \ 'guifg': a:fg_hex,
          \ 'guibg': a:bg_hex,
          \ 'guisp': 'NONE',
          \ 'ctermfg': 'NONE',
          \ 'ctermbg': 'NONE',
          \ }
  endfunction

  " Define colors from Pywal
  let s:fg       = l:colors['special']['foreground']
  let s:bg       = l:colors['special']['background']
  let s:color0   = l:colors['colors']['color0']
  let s:color1   = l:colors['colors']['color1']
  let s:color2   = l:colors['colors']['color2']
  let s:color3   = l:colors['colors']['color3']
  let s:color4   = l:colors['colors']['color4']
  let s:color5   = l:colors['colors']['color5']
  let s:color6   = l:colors['colors']['color6']
  let s:color7   = l:colors['colors']['color7']
  let s:color8   = l:colors['colors']['color8']
  let s:color9   = l:colors['colors']['color9']
  let s:color10  = l:colors['colors']['color10']
  let s:color11  = l:colors['colors']['color11']
  let s:color12  = l:colors['colors']['color12']
  let s:color13  = l:colors['colors']['color13']
  let s:color14  = l:colors['colors']['color14']
  let s:color15  = l:colors['colors']['color15']

  " Normal mode
  let s:palette.normal = {
        \ 'airline_a': s:color(s:color2, s:color0, 'bold'),
        \ 'airline_b': s:color(s:fg, s:color8, ''),
        \ 'airline_c': s:color(s:fg, s:bg, ''),
        \ 'airline_x': s:color(s:fg, s:bg, ''),
        \ 'airline_y': s:color(s:fg, s:color8, ''),
        \ 'airline_z': s:color(s:color2, s:color0, 'bold'),
        \ }

  " Insert mode
  let s:palette.insert = {
        \ 'airline_a': s:color(s:color10, s:color0, 'bold'),
        \ 'airline_b': s:color(s:fg, s:color8, ''),
        \ 'airline_c': s:color(s:fg, s:bg, ''),
        \ 'airline_x': s:color(s:fg, s:bg, ''),
        \ 'airline_y': s:color(s:fg, s:color8, ''),
        \ 'airline_z': s:color(s:color10, s:color0, 'bold'),
        \ }

  " Visual mode
  let s:palette.visual = {
        \ 'airline_a': s:color(s:color5, s:color0, 'bold'),
        \ 'airline_b': s:color(s:fg, s:color8, ''),
        \ 'airline_c': s:color(s:fg, s:bg, ''),
        \ 'airline_x': s:color(s:fg, s:bg, ''),
        \ 'airline_y': s:color(s:fg, s:color8, ''),
        \ 'airline_z': s:color(s:color5, s:color0, 'bold'),
        \ }

  " Replace mode
  let s:palette.replace = {
        \ 'airline_a': s:color(s:color9, s:color0, 'bold'),
        \ 'airline_b': s:color(s:fg, s:color8, ''),
        \ 'airline_c': s:color(s:fg, s:bg, ''),
        \ 'airline_x': s:color(s:fg, s:bg, ''),
        \ 'airline_y': s:color(s:fg, s:color8, ''),
        \ 'airline_z': s:color(s:color9, s:color0, 'bold'),
        \ }

  " Inactive mode
  let s:palette.inactive = {
        \ 'airline_a': s:color(s:fg, s:bg, ''),
        \ 'airline_b': s:color(s:fg, s:bg, ''),
        \ 'airline_c': s:color(s:fg, s:bg, ''),
        \ 'airline_x': s:color(s:fg, s:bg, ''),
        \ 'airline_y': s:color(s:fg, s:bg, ''),
        \ 'airline_z': s:color(s:fg, s:bg, ''),
        \ }

  " Tabline
  let s:palette.tabline = {
        \ 'airline_tabsel': s:color(s:fg, s:color2, 'bold'),
        \ 'airline_tab': s:color(s:fg, s:color8, ''),
        \ 'airline_tabsel_sep': s:color(s:color2, s:bg, ''),
        \ 'airline_tab_sep': s:color(s:color8, s:bg, ''),
        \ }

  " Assign the palette to the pywal theme
  let g:airline#themes#pywal#palette = s:palette

  " Set the theme and load it
  let g:airline_theme = 'pywal'
  if exists('*airline#load_theme')
    call airline#load_theme()
  else
    echo "Airline is not installed or outdated."
    return
  endif

  if !g:statusline_themer_silent
    echo "Applied Pywal statusline theme."
  endif
endfunction

" Function to start Pywal monitoring
function! statusline_themer#start_pywal_monitor() abort
  if !has('timers')
    echo "Vim does not support timers. Pywal integration disabled."
    return
  endif
  let g:statusline_themer_pywal_last_mtime = -1
  let g:statusline_themer_pywal_timer = timer_start(g:statusline_themer_pywal_update_interval, 'statusline_themer#pywal_update', {'repeat': -1})
  " Apply the Pywal theme immediately
  call statusline_themer#apply_pywal_theme()
endfunction

" Function to stop Pywal monitoring
function! statusline_themer#stop_pywal_monitor() abort
  if exists('g:statusline_themer_pywal_timer')
    call timer_stop(g:statusline_themer_pywal_timer)
    unlet g:statusline_themer_pywal_timer
  endif
endfunction

" Function to toggle Pywal mode
function! statusline_themer#toggle_pywal_mode() abort
  if g:statusline_themer_mode ==# 'pywal'
    let g:statusline_themer_mode = 'manual'
    call statusline_themer#stop_pywal_monitor()
    echo "Switched to manual mode."
    " Load the saved theme
    call statusline_themer#load_saved_theme()
  else
    let g:statusline_themer_mode = 'pywal'
    call statusline_themer#start_pywal_monitor()
    echo "Switched to Pywal mode."
  endif
endfunction

" Function to apply Pywal theme manually
function! statusline_themer#apply_pywal() abort
  call statusline_themer#apply_pywal_theme()
endfunction
