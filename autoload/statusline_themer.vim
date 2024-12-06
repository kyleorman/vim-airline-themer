" autoload/statusline_themer.vim

function! s:get_lock_dir() abort
  let l:xdg_runtime = empty($XDG_RUNTIME_DIR) ? '/tmp' : $XDG_RUNTIME_DIR
  return l:xdg_runtime . '/tmux-statusline-monitor'
endfunction

function! s:create_vim_lock() abort
  let l:lock_dir = s:get_lock_dir()
  if !isdirectory(l:lock_dir)
    call mkdir(l:lock_dir, 'p')
  endif
  call writefile([''], l:lock_dir . '/vim-controlled')
endfunction

function! s:remove_vim_lock() abort
  let l:lock_file = s:get_lock_dir() . '/vim-controlled'
  if filereadable(l:lock_file)
    call delete(l:lock_file)
  endif
endfunction

function! s:get_lock_dir() abort
  let l:xdg_runtime = empty($XDG_RUNTIME_DIR) ? '/tmp' : $XDG_RUNTIME_DIR
  return l:xdg_runtime . '/tmux-statusline-monitor'
endfunction

function! s:create_vim_lock() abort
  let l:lock_dir = s:get_lock_dir()
  if !isdirectory(l:lock_dir)
    call mkdir(l:lock_dir, 'p')
  endif
  call writefile([''], l:lock_dir . '/vim-controlled')
endfunction

function! s:remove_vim_lock() abort
  let l:lock_file = s:get_lock_dir() . '/vim-controlled'
  if filereadable(l:lock_file)
    call delete(l:lock_file)
  endif
endfunction

if exists('g:loaded_statusline_themer_autoload')
  finish
endif
let g:loaded_statusline_themer_autoload = 1

function! statusline_themer#init() abort
  if !exists('*fzf#run')
    echohl ErrorMsg | echo "vim-statusline-themer requires fzf.vim" | echohl None
    return
  endif

  if exists('*themer#check_pywal_update')
    augroup StatuslineThemerPywal
      autocmd!
      autocmd User ThemerPywalUpdate call statusline_themer#apply_pywal()
      autocmd User ThemerColorsChanged call statusline_themer#preserve_theme()
    augroup END
  endif

  call statusline_themer#load_saved_theme()

  if g:statusline_themer_mode ==# 'pywal'
    call statusline_themer#start_pywal_monitor()
  endif
endfunction

function! statusline_themer#xdg_config_dir() abort
  let l:xdg_config_home = empty($XDG_CONFIG_HOME) ? expand('~/.config') : $XDG_CONFIG_HOME
  return l:xdg_config_home . '/vim-statusline-themer'
endfunction

function! statusline_themer#load_theme_settings() abort
  let l:config_file = statusline_themer#xdg_config_dir() . '/settings.json'
  if filereadable(l:config_file)
    try
      let s:settings = json_decode(join(readfile(l:config_file), "\n"))
    catch
      let s:settings = {}
    endtry
  else
    let s:settings = {}
  endif
  return s:settings
endfunction

function! statusline_themer#save_theme_settings() abort
  let l:config_dir = statusline_themer#xdg_config_dir()
  if !isdirectory(l:config_dir)
    call mkdir(l:config_dir, 'p')
  endif

  let l:config_file = l:config_dir . '/settings.json'
  " Fix the dictionary initialization
  let s:settings = exists('s:settings') ? s:settings : {}
  let s:settings.theme = exists('g:airline_theme') ? g:airline_theme : 'default'
  let s:settings.mode = g:statusline_themer_mode

  if s:settings.theme ==# 'pywal' && g:statusline_themer_mode ==# 'manual'
    let l:colors_file = expand('~/.cache/wal/colors.json')
    if filereadable(l:colors_file)
      let s:settings.cached_colors = json_decode(join(readfile(l:colors_file), "\n"))
    endif
  endif

  try
    call writefile([json_encode(s:settings)], l:config_file)
  catch
    echohl ErrorMsg | echo "Failed to save statusline theme settings" | echohl None
  endtry
endfunction

function! statusline_themer#find_themes() abort
  let l:themes = []
  for l:dir in g:statusline_themer_dirs
    let l:dir = expand(l:dir)
    if isdirectory(l:dir)
      let l:files = globpath(l:dir, '*.vim', 0, 1)
      for l:file in l:files
        let l:theme = fnamemodify(l:file, ':t:r')
        call add(l:themes, l:theme)
      endfor
    endif
  endfor
  return uniq(sort(l:themes))
endfunction

function! statusline_themer#complete_themes(arglead, cmdline, cursorpos) abort
  let l:themes = statusline_themer#find_themes()
  call add(l:themes, 'pywal')
  return filter(l:themes, 'v:val =~ "^' . a:arglead . '"')
endfunction

function! statusline_themer#select_theme(...) abort
  if a:0 > 0
    call statusline_themer#apply_theme(a:1)
  else
    let l:themes = statusline_themer#find_themes()
    call add(l:themes, 'pywal')
    
    call fzf#run(fzf#wrap({
          \ 'source': l:themes,
          \ 'sink': function('statusline_themer#apply_theme'),
          \ 'options': '--prompt="Statusline Theme> "'
          \ }))
  endif
endfunction

function! statusline_themer#apply_theme(theme, ...) abort
  let l:is_pywal = get(a:, 1, 0)
  let s:applying_theme = 1

  " Create lock file when taking control
  call s:create_vim_lock()

  if !exists('*airline#load_theme')
    echohl ErrorMsg | echo "vim-airline not found" | echohl None
    return
  endif

  if a:theme ==# 'pywal' && !l:is_pywal
    if g:statusline_themer_mode ==# 'manual'
      let l:settings = statusline_themer#load_theme_settings()
      if has_key(l:settings, 'cached_colors')
        call s:apply_pywal_colors(l:settings.cached_colors)
      else
        call statusline_themer#apply_pywal()
      endif
    else
      call statusline_themer#apply_pywal()
    endif
    let s:applying_theme = 0
    return
  endif

  let g:airline_theme = a:theme
  call airline#load_theme()

  if g:statusline_themer_tmuxline_save && exists(':Tmuxline')
    Tmuxline airline
    silent! TmuxlineSnapshot! ~/.tmuxline.conf
    if executable('tmux')
      call system('tmux source-file ~/.tmuxline.conf')
    endif
  endif

  let s:applying_theme = 0
endfunction

function! statusline_themer#preserve_theme() abort
  if get(s:, 'applying_theme', 0)
    return
  endif

  if exists('g:airline_theme')
    let s:preserved_airline_theme = g:airline_theme
    call timer_start(10, {-> statusline_themer#reapply_preserved_theme()})
  endif
endfunction

function! statusline_themer#reapply_preserved_theme() abort
  if exists('s:preserved_airline_theme')
    let s:applying_theme = 1
    let g:airline_theme = s:preserved_airline_theme
    if exists('*airline#load_theme')
      call airline#load_theme()
      if g:statusline_themer_tmuxline_save && exists(':Tmuxline')
        Tmuxline airline
        silent! TmuxlineSnapshot! ~/.tmuxline.conf
      endif
    endif
    let s:applying_theme = 0
  endif
endfunction

function! s:apply_pywal_colors(colors_dict) abort
  let g:airline#themes#pywal#palette = {}

  let s:N1 = [a:colors_dict['special']['background'], a:colors_dict['colors']['color2'], 232, 2]
  let s:N2 = [a:colors_dict['special']['foreground'], a:colors_dict['colors']['color8'], 255, 8]
  let s:N3 = [a:colors_dict['special']['foreground'], a:colors_dict['special']['background'], 255, 233]

  let s:I1 = [a:colors_dict['special']['background'], a:colors_dict['colors']['color4'], 232, 4]
  let s:I2 = s:N2
  let s:I3 = s:N3

  let s:V1 = [a:colors_dict['special']['background'], a:colors_dict['colors']['color5'], 232, 5]
  let s:V2 = s:N2
  let s:V3 = s:N3

  let s:R1 = [a:colors_dict['special']['background'], a:colors_dict['colors']['color1'], 232, 1]
  let s:R2 = s:N2
  let s:R3 = s:N3

  let s:IA = [a:colors_dict['special']['foreground'], a:colors_dict['special']['background'], 244, 233]

  let g:airline#themes#pywal#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
  let g:airline#themes#pywal#palette.insert = airline#themes#generate_color_map(s:I1, s:I2, s:I3)
  let g:airline#themes#pywal#palette.visual = airline#themes#generate_color_map(s:V1, s:V2, s:V3)
  let g:airline#themes#pywal#palette.replace = airline#themes#generate_color_map(s:R1, s:R2, s:R3)
  let g:airline#themes#pywal#palette.inactive = airline#themes#generate_color_map(s:IA, s:IA, s:IA)

  let g:airline#themes#pywal#palette.normal.airline_warning = [a:colors_dict['special']['background'], a:colors_dict['colors']['color3'], 232, 3]
  let g:airline#themes#pywal#palette.normal.airline_error = [a:colors_dict['special']['background'], a:colors_dict['colors']['color1'], 232, 1]

  for mode in ['insert', 'visual', 'replace', 'inactive']
    let g:airline#themes#pywal#palette[mode].airline_warning = g:airline#themes#pywal#palette.normal.airline_warning
    let g:airline#themes#pywal#palette[mode].airline_error = g:airline#themes#pywal#palette.normal.airline_error
  endfor

  call statusline_themer#apply_theme('pywal', 1)
endfunction

function! statusline_themer#apply_pywal() abort
  if !exists('*json_decode')
    echohl ErrorMsg | echo "Pywal integration requires Vim with +json" | echohl None
    return
  endif

  let l:colors_file = expand('~/.cache/wal/colors.json')
  if !filereadable(l:colors_file)
    echohl ErrorMsg | echo "Pywal colors.json not found" | echohl None
    return
  endif

  try
    let l:colors = json_decode(join(readfile(l:colors_file), "\n"))
    call s:apply_pywal_colors(l:colors)
  catch
    echohl ErrorMsg | echo "Failed to apply pywal colors" | echohl None
  endtry
endfunction

function! statusline_themer#start_pywal_monitor() abort
  if exists('*themer#check_pywal_update')
    return
  endif

  if !has('timers')
    echohl ErrorMsg | echo "Pywal monitoring requires Vim with +timers" | echohl None
    return
  endif

  if exists('s:pywal_timer')
    call timer_stop(s:pywal_timer)
  endif

  let s:pywal_last_mtime = getftime(expand('~/.cache/wal/colors.json'))
  let s:pywal_timer = timer_start(g:statusline_themer_pywal_update_interval,
        \ function('s:check_pywal_updates'), {'repeat': -1})
  
  call statusline_themer#apply_pywal()
endfunction

function! s:check_pywal_updates(timer) abort
  let l:current_mtime = getftime(expand('~/.cache/wal/colors.json'))
  if l:current_mtime != s:pywal_last_mtime
    let s:pywal_last_mtime = l:current_mtime
    call statusline_themer#apply_pywal()
  endif
endfunction

function! statusline_themer#toggle_pywal_mode() abort
  let g:statusline_themer_mode = g:statusline_themer_mode ==# 'pywal' ? 'manual' : 'pywal'
  call statusline_themer#save_theme_settings()

  if g:statusline_themer_mode ==# 'pywal'
    call statusline_themer#start_pywal_monitor()
  else
    if exists('s:pywal_timer')
      call timer_stop(s:pywal_timer)
      unlet s:pywal_timer
    endif
    call statusline_themer#load_saved_theme()
  endif

  if !g:statusline_themer_silent
    echo "Statusline mode: " . g:statusline_themer_mode
  endif
endfunction

function! statusline_themer#save_theme() abort
  if exists('g:airline_theme')
    call statusline_themer#save_theme_settings()
    
    if !g:statusline_themer_silent
      if g:statusline_themer_mode ==# 'pywal'
        echo "Saved pywal theme configuration"
      else
        echo "Saved theme: " . g:airline_theme
      endif
    endif
  else
    echohl ErrorMsg | echo "No statusline theme to save" | echohl None
  endif
endfunction

function! statusline_themer#load_saved_theme() abort
  let l:settings = statusline_themer#load_theme_settings()
  if has_key(l:settings, 'theme')
    if l:settings.theme ==# 'pywal'
      if g:statusline_themer_mode ==# 'manual' && has_key(l:settings, 'cached_colors')
        call s:apply_pywal_colors(l:settings.cached_colors)
      else
        call statusline_themer#apply_pywal()
      endif
    else
      call statusline_themer#apply_theme(l:settings.theme)
    endif
  endif
endfunction

function! statusline_themer#cleanup() abort
  if exists('s:pywal_timer')
    call timer_stop(s:pywal_timer)
  endif
  call s:remove_vim_lock()
endfunction

function! statusline_themer#reload() abort
  if g:statusline_themer_mode ==# 'pywal'
    call statusline_themer#apply_pywal()
  else
    call statusline_themer#load_saved_theme()
  endif
endfunction
