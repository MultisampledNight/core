" Non-fully compliant but okay TOML parser.
" This file uses the method operator (->) quite extensively:
" It just uses the expression before `->`
" as the first argument for the function after `->`.

" Parses a subset of TOML.
" `expr` has to be a list of strings,
" with each list entry being a line.
"
" Just throw `readfile` into it.
"
" The supported subset is:
"
" - Sections (of any depth)
" - Key-value pairs
" - Literal strings (i.e. no ", only ')
" - Comments
" - Empty lines
function TomlDecode(expr)
  " What to parse into.
  let out = {}
  " How far into the output tree are we atm?
  let depth = []

  for line in a:expr
    " remove the comment
    let line = line->split("#", v:true)[0]->trim()

    " see what we're dealing with
    if line == ''
      " empty line, nothing to do /shrug
      continue
    elseif line =~ '^\[.*\]$'
      " section, let's readjust where to write keys to
      let depth = line[1:-2]->split('\.')
    elseif line =~ '='
      " key-value pair
      " we only really care about the first equals sign,
      " all after are irrelevant
      let parts = line->split("=")
      let ident = parts[0]->trim()
      let value = parts[1:]->join("=")->trim()->s:Literal()

      eval out->s:Put(depth + [ident], value)
    else
      " no idea /shrug
      throw $"cannot parse TOML line `{line}`"
    endif
  endfor

  return out
endfunction

" `store` is a nested dictionary,
" `path` is a list of keys to traverse
" to where to store `value`.
"
" Creates dictionaries as necessary along the way.
function s:Put(store, path, value)
  let depth = a:path[:-2]
  let ident = a:path[-1]

  let cursor = a:store

  for key in depth
    " TODO: what if the key does exist already, but is not a dict?
    " (will error out atm)
    if !cursor->has_key(key)
      let cursor[key] = {}
    endif
    let cursor = cursor[key]
  endfor

  let cursor[ident] = a:value
endfunction

function s:Literal(source)
  if a:source =~ "^'.*'$"
    return a:source[1:-2]
  else
    throw $"cannot parse TOML literal `{a:source}` (note that not all features are supported)"
  endif
endfunction
