let notes = "~/notes"
let zero = notes . "/zero"
let daily_note = zero . "/daily-note"

function Notes()
  let s:list = g:data.regex.list
  " other regex engines use the parens to denote groups
  " but the vim one doesn't!
  let s:checkbox = g:data.regex.checkbox->filter('v:val !~ "[()]"')
  let s:fills = g:data.task.fills

  let s:task = s:list . s:checkbox

  " Remember: The shortcut must be prefixed with the leader in use.
  let shortcuts = items(#{p: ">", h: "/", l: "x"})
  call extend(shortcuts, map(split(": ? ! -"), {_, ch -> [ch, ch]}))

  for [key, fill] in shortcuts
    exe $"noremap <Leader>{key} <Cmd>call InteractTask('{fill}')<Enter>"
  endfor

  set tw=60 sw=2 ts=2 sts=0 et

  noremap <Leader>m <Cmd>call OpenToday()<Enter>

  noremap <LeftRelease> <Cmd>call ToggleIfCheckbox("x")<Enter>
  noremap <2-LeftMouse> <Cmd>call ToggleIfCheckbox(">")<Enter>
  noremap <RightRelease> <Cmd>call ToggleIfCheckbox("/")<Enter>

  inoremap <Enter> <Cmd>call Enter()<Enter>
  " ax<BS> is only to "realize" space if the cursor is at the end of the line
  nnoremap <A-Tab> ax<BS><Esc>>>2l
  nnoremap <A-S-Tab> ax<BS><Esc><lt><lt>2h
  inoremap <A-Tab> <Esc>ax<BS><Esc>>>2la
  inoremap <A-S-Tab> <Esc>ax<BS><Esc><lt><lt>ha

  " insert brackets around the selected text
  vnoremap <Leader>y <Esc>g`<i[<Esc>g`>la]<Esc>
  " or just on the current word in normal mode
  nmap <Leader>y viw<Leader>y
endfunction

function OpenToday()
  let today = strftime(g:date_format)
  call OpenFile(g:daily_note . "/" . today . ".typ")
endfunction

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
    call CreateTask(cfg.start_line)
  else
    call CreateTask()
  endif

  call TaskOverview()
endfunction

" Returns in which context the user is currently typing in.
" The context is a list with 2 items:
" A string identification of the context and
" a dictionary for further configuration.
"
" One of (cursor is not moved unless explicitly listed and
" `move_cursor` is truthy):
" [v:null, {}] => no notable context
" ["list", {start_line}] => user is in a list entry *without* a checkbox.
"   The list entry starts at `start_line`.
" ["task", {start_line}] => user is in a list entry *with* a checkbox,
"   the cursor moves to the checkbox fill.
"   The task entry starts at `start_line`.
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
  " no i can't use treesitter for this,
  " as e.g. [/] is not parsed by it (it's a cancelled checkbox)
  let list = search(s:list, "cbWn", limit)
  let flags = a:move_cursor ? "cbWe" : "cbWn"
  let task = search(s:task, flags, limit)

  " did any of them match at all?
  if list == 0 && task == 0
    let ctx = v:null
  elseif list <= task
    norm h
    let ctx = "task"
  else
    let ctx = "list"
  endif

  let ctx = [ctx, {}]

  if ctx[0] != v:null
    norm mY
    exe $'norm {list}G'
    norm ^

    let ctx[1]["start_line"] = list
    let ctx[1]["list_marker"] = s:cursorchar()

    norm g`Y
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
  let current = s:cursorchar()
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
  if search(s:list, "cWe", line("."))
    " reuse the list marker then
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
  silent exe $"norm $?{s:checkbox}\<Enter>l"
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

  let [ctx, cfg] = Context()

  if ctx == v:null
    let marker = ""
  else
    let marker = cfg.list_marker . " "
  endif

  " tasks are a kind of list
  " so do preserve the list marker, but add the checkbox as well
  if ctx == "task"
    let marker .= "[ ] "
  endif

  let concretize_indent = " \<BS>"

  exe $"norm! {insertion_start}\<Enter>{concretize_indent}{marker}\<Esc>"
  call feedkeys("\<Right>")
endfunction

" Counts and returns how many tasks there are
" with the given fill character
" in this file.
" The fill character is a regex — use "." for any fill.
function TaskCount(fill = ".")
  " note that the . is escaped — otherwise the first character in the regex
  " would be replaced
  let expr = substitute(s:task, '\.', a:fill, "")
  " 0 <=> no limit (default would be 100)
  return searchcount(#{pattern: expr, maxcount: 0}).total
endfunction

" Echoes a short overview over how many tasks there are in this file
" and a breakdown of their states.
" Useful for getting an idea of how much progress has been made.
function TaskOverview()
  " would like to express this more functionally
  " but it seems like there's no map-ish construction
  " that can effectively convert from string to list/dict

  " see how often each state is used
  " using a list rather than a dict since we want to preserve the order
  " (see top of the file, s:fills definition)
  let counts = []

  for ch in s:fills
    let times = TaskCount(ch)

    if times == 0
      " displaying nonexistent states would be noisy
      " so we don't!
      continue
    endif

    call add(counts, $"{times} [{ch}]")
  endfor

  " print them nicely
  let total = TaskCount()
  if total == 0
    echo "No tasks"
    return
  endif

  echon total." tasks"

  if empty(counts)
    echo
    return
  endif

  " alright, let's break it down then
  echon " (" . join(counts, ", ") . ")"
endfunction

" Returns the character currently under the cursor.
function s:cursorchar()
  return getline(".")[charcol(".") - 1]
endfunction

autocmd BufNewFile,BufRead ~/notes/*.{md,typ} call Notes()

command Tasks call TaskOverview()

