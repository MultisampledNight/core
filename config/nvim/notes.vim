let notes = "~/notes"
let zero = notes . "/zero"
let daily_note = zero . "/daily-note"
let template = zero . "/template"

function Notes()
  let data = "~/studio/typst/packages/flow/asset/data.toml"
  let data = data->expand()->readfile()->TomlDecode()

  let g:date_format = data.date.short
  let g:datetime_format = data.date.long

  let s:list = data.regex.list
  " other regex engines use the parens to denote groups
  " but the vim one doesn't!
  let s:checkbox = data.regex.checkbox->filter('v:val !~ "[()]"')
  let s:fills = data.task.fills

  let s:task = s:list . s:checkbox

  " Remember: The shortcut must be prefixed with the leader in use.
  let shortcuts = items(#{p: ">", h: "/", l: "x"})
  call extend(shortcuts, map(split(": ? ! -"), {_, ch -> [ch, ch]}))

  for [key, fill] in shortcuts
    exe $"noremap <Leader>{key} <Cmd>call InteractTask('{fill}')<CR>"
  endfor

  set tw=60 sw=2 ts=2 sts=0 et

  noremap <Leader>m <Cmd>call OpenToday()<CR>

  noremap <LeftRelease> <Cmd>call ToggleIfCheckbox("x")<CR>
  noremap <2-LeftMouse> <Cmd>call ToggleIfCheckbox(">")<CR>
  noremap <RightRelease> <Cmd>call ToggleIfCheckbox("/")<CR>

  inoremap <Enter> <Cmd>call Enter()<CR>
  nnoremap <A-Tab> >>
  nnoremap <A-S-Tab> <<

  " always have a pane on the right that shows headings
lua <<EOF
  require("trouble").open({
    mode = "symbols",
    filter = {
      buf = 0,
    },
    win = {
      position = "left",
      wo = {
        -- otherwise the heading name is shown twice
        winhighlight = "Comment:Hide",
      },
    }
  })
EOF
endfunction

function Associate(pattern, template)
  exe 'au BufNewFile '.a:pattern.' call Template("'.a:template.'")'
endfunction
function RealizeVariables()
  " substitute cfg values
  let vars = #{
    \ title: expand("%:t:r"),
    \ now: strftime(g:datetime_format),
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
  exe 'norm /'.regex."\<CR>\"_d//e\<CR>"

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

  Upd
endfunction
function OpenToday()
  let today = strftime(g:date_format)
  exe "edit ".g:daily_note."/".today.".typ"
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
  let entry = search(s:list, "cbWn", limit)
  let flags = a:move_cursor ? "cbWe" : "cbWn"
  let task = search(s:task, flags, limit)

  " did any of them match at all?
  if entry == 0 && task == 0
    let ctx = v:null
  elseif entry <= task
    norm h
    let ctx = "task"
  else
    let ctx = "list"
  endif

  let ctx = [ctx, {}]

  if ctx[0] != v:null
    let ctx[1]["start_line"] = entry
    let ctx[1]["list_marker"] = s:firstNonEmpty()
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
  return searchcount(#{pattern: expr}).total
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

    call add(counts, $"{times} × [{ch}]")
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

" Returns the first non-empty character.
function s:firstNonEmpty()
  norm mY

  norm ^
  let ch = s:cursorchar()

  norm g`Y
  return ch
endfunction

autocmd BufNewFile,BufRead ~/notes/*.{md,typ} call Notes()

" Needs to be ordered from most specific to least specific,
" since the first successful `Template` call inhibits all others
call Associate(daily_note."/*.typ", "Daily.typ")
call Associate(notes."/*.typ", "Note.typ")

command RVar call RealizeVariables()
command Tasks call TaskOverview()

