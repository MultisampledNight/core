let notes = "~/notes"
let zero = notes . "/zero"
let daily_note = zero . "/daily-note"
let template = zero . "/template"

let g:date_format = "%Y-%m-%d"

function NotesMode()
  call AutoWrite(v:true)
  set tw=80 sw=2 ts=2 sts=0 et

  noremap <Space><Enter> <Cmd>call OpenToday()<CR>
  noremap <Space>p <Cmd>call InteractTask(">")<CR>
  noremap <Space>h <Cmd>call InteractTask("/")<CR>
  noremap <Space>l <Cmd>call InteractTask("x")<CR>
  noremap <LeftRelease> <Cmd>call ToggleIfCheckbox("x")<CR>
  noremap <2-LeftMouse> <Cmd>call ToggleIfCheckbox(">")<CR>
  noremap <RightRelease> <Cmd>call ToggleIfCheckbox("/")<CR>

  inoremap <Enter> <Cmd>call Enter()<CR>
endfunction

function Associate(pattern, template)
  exe 'au BufNewFile '.a:pattern.' call Template("'.a:template.'")'
endfunction
function RealizeVariables()
  " substitute cfg values
  let vars = #{
    \ title: expand("%:t:r"),
    \ today: strftime(g:date_format),
  \ }
  
  for [name, value] in items(vars)
    exe 'sil! %s/\$'.name.'/'.value.'/Ieg'
  endfor

  noh

  " position the cursor
  let regex = '\$cursor\(\.\(normal\|insert\)\|\)'
  let matches = matchbufline(bufnr("%"), regex, 1, "$", #{submatches: v:true})
  if empty(matches)
    norm G
    return
  endif

  let line = matches[0].lnum
  let kind = matches[0].submatches[1]
  exe 'norm /'.regex."\<CR>"_d//e\<CR>"

  if kind == 'insert'
    startinsert
  endif

  noh
endfunction
function Template(name)
  if exists("b:templated")
    return
  endif
  let b:templated = v:true
  exe "read " . g:template . "/" . a:name

  norm gg"_dd
  call RealizeVariables()

  silent update
endfunction
function OpenToday()
  let today = strftime(g:date_format)
  exe "edit ".g:daily_note."/".today.".typ"
endfunction

" no i can't use treesitter for this,
" as e.g. [/] is not parsed by it (it's a cancelled checkbox)
let s:marker = '^\s*[-+/] '
let s:checkbox = '\[.\]'
let s:task = s:marker . s:checkbox

function InteractTask(intended)
  if mode() == "v"
    norm v
  endif

  " remember where we started, the individual functions take care of resetting
  " as suited for them
  norm mJ

  let [ctx, cfg] = Context(v:true)
  if ctx == "task"
    call ToggleTask(a:intended)
  elseif ctx == "list"
    call CreateTask(cfg.marker_line)
  else
    call CreateTask()
  endif
endfunction

" Returns in which context the user is currently typing in.
" The context is a list with 2 items:
" A string identification of the context and
" a dictionary for further configuration.
"
" One of (cursor is not moved unless explicitly listed and
" `move_cursor` is truthy):
" [v:null, {}] => no notable context
" ["list", {marker_line}] => user is in a list entry *without* a checkbox.
"   The list entry starts at `marker_line`.
" ["task", {marker_line}] => user is in a list entry *with* a checkbox,
"   the cursor moves to the checkbox fill.
"   The task entry starts at `marker_line`.
"
" This overwrites the `K` mark with the initial cursor position
" as a side effect.
function Context(move_cursor = v:false)
  " find the start of the paragraph (or start of file)
  norm mK
  " \n\n cannot be used since search seems to accept only single-line matches
  let limit = search("^$", "bWn")
  norm $

  " let's look at what we actually want to do
  let entry = search(s:marker, "cbWn", limit)
  let flags = a:move_cursor ? "cbWe" : "cbWn"
  let task = search(s:task, flags, limit)

  " did any of them match at all?
  if entry == 0 && task == 0
    let ctx = [v:null, {}]
  elseif entry <= task
    norm h
    let ctx = ["task", #{marker_line: task}]
  else
    let ctx = ["list", #{marker_line: entry}]
  endif

  if !a:move_cursor
    norm g`K
  endif

  return ctx
endfunction

" Assumes the cursor is already on the checkbox fill.
" If in doubt, use `Context` to do this for you.
function ToggleTask(intended)
  " cursor is at end of match atm, let's look inside
  let current = getline(".")[charcol(".") - 1]
  let final = a:intended
  if current == a:intended
    let final = " "
  endif

  exe $"norm r{final}"

  " reset so the user can continue typing where they left off
  norm g`J
endfunction

function ConvertEntryToTask(entry_line)
  call setcursorcharpos(a:entry_line, 0)
  exe 'norm ^la[ ] '
  norm g`J
endfunction

function CreateTask(start_line = line("."))
  call setcursorcharpos(a:start_line, 0)

  " does the line contain a list marker already? if so, move to its end
  norm ^
  if search(s:marker, "cWe", line("."))
    " reuse the marker then
    let action = 'a[ ] '
  else
    " nope, no marker qwq
    let action = 'i- [ ] '
  endif

  " insert the task chars
  exe 'norm ' . action
  " reset to where the user was, but such that the cursor is at the same text
  exe 'norm g`J' . (len(action) - 1) . 'l'
endfunction

function ToggleIfCheckbox(intended)
  let [line, col] = getpos("v")[1:2]

  if col <= 1
    " checkbox can start the earliest at pos 2 → can't be hit
    return
  endif

  let around = getline(line)[col - 3 : col + 1]
  if around !~ $".*{s:checkbox}.*"
    " cursor didn't hit start/end of a checkbox
    return
  endif

  call InteractTask(a:intended)

  " position the cursor so it's at the center of the checkbox
  silent exe $"norm $?{s:checkbox}\<CR>l"
endfunction

" Presses enter, preserving the context
" by creating task or list markers as-needed
" (or also just doing nothing).
function Enter()
  " recall that in insert mode, the cursor is *between* characters
  " there's one special case here: the cursor being at the end of a line
  " this is not reachable with `i`. it has to be done with one of `aAoOcC`
  " if the user did that, the cursor column is at the highest possible for
  " this line <=> text_after_cursor is true
  " but to insert any text, we have to reset to normal mode and then go into
  " insert mode again. there appears to be no way in VimScript to just stay in
  " insert mode
  " hence the cursor would always reset to before the last character on the line,
  " even though the user was at the end of the line!

  let text_after_cursor = col(".") != col("$")
  let insertion_start = text_after_cursor ? "i" : "a"

  let [ctx, _cfg] = Context()

  if ctx == "task"
    let marker = "- [ ] "
  elseif ctx == "list"
    let marker = "- "
  else
    let marker = ""
  endif
  let concretize_indent = " \<BS>"

  exe $"norm! {insertion_start}\<Enter>{concretize_indent}{marker}\<Esc>"
  call feedkeys("\<Right>")
endfunction

functuion Associate()
endfunction

autocmd BufNewFile,BufRead ~/notes/*.{md,typ} call NotesMode()

" Needs to be ordered from most specific to least specific,
" since the first successful `Template` call inhibits all others
call Associate(daily_note."/*.typ", "Daily.typ")
call Associate(notes."/*.typ", "Note.typ")

