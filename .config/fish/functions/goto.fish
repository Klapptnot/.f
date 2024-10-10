#! /bin/env fish

# |>----|>----|>----|><-><|----<|----<|----<|
# |>      from Klapptnot's unix setup      <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# Small utility to go to folders by alias

function goto -d 'Alias based fast cd (change dir)'
  argparse -x h,l h/help l/list p/print -- $argv
  or return 1

  if set -q _flag_help
    set -l help \
      '{f87}goto{r} - Alias based fast cd (change dir)' \
      'Usage: goto <path|alias> [...MODIFIERS]' \
      '       goto -h|--help     - Show this message and exit' \
      '       goto -l|--list     - Show the aliases list' \
      '       goto -p|--print    - Print path instead of going to it' \
      'Example' \
      '  # go to folder with alias "nf"' \
      '  goto nf' \
      '  # format "of" alias with "images"' \
      '  goto of images' \
      '  # go to home folder' \
      '  goto'
    set help (string join '\n' $help[1..-1])
    print $help
    return
  else if set -q _flag_list
    if not test -f $HOME/.config/goto.idx
      print '{f85}[INFO]{r} Index file not found, printing default aliases\n'
      set -l PATH_INDEX_CONTENT \
        'cfg &!HOME;/.config' \
        'ubin /usr/bin' \
        'ulib /usr/lib' \
        'uetc /usr/etc' \
        'dtkp  &!HOME;/Desktop' \
        'nvc &*cfg;/nvim'
      print '{}\n' $PATH_INDEX_CONTENT
      return 1
    end

    set -l keys (cat $HOME/.config/goto.idx | grep -Po '^\s*\K[^\s]+')
    set -l alias (cat $HOME/.config/goto.idx | grep -Po '(?<=\s)[^\s].*(?=$)')
    set -l keyL 0
    set -l aliasL 0
    for i in (seq 1 (count $keys))
      test (string length $keys[$i]) -gt $keyL; and set keyL (string length $keys[$i])
      test (string length $alias[$i]) -gt $aliasL; and set aliasL (string length $alias[$i])
    end
    set keyl2 (math $keyL + 2)
    set aliasl2 (math $aliasL + 2)
    set count_k (string length (count $keys))
    set -f table (print '╭{─^'(math $count_k + 2)'}┬{─^'{$keyl2}'}┬{─^'{$aliasl2}'}╮' "─" "─" "─")
    set -a table (print '│ {^'{$count_k}'} │ {^'{$keyL}'} │ {^'{$aliasL}'} │' "#" "Alias" "Content")
    set -a table (print '├{─^'(math $count_k + 2)'}┼{─^'{$keyl2}'}┼{─^'{$aliasl2}'}┤' "─" "─" "─")
    for i in (seq 1 (count $keys))
      set -a table (print '│ {'{$count_k}'} │ {'{$keyL}'} │ {'{$aliasL}'} │' $i $keys[$i] $alias[$i])
    end
    set -a table (print '╰{─^'(math $count_k + 2)'}┴{─^'{$keyl2}'}┴{─^'{$aliasl2}'}╯' "─" "─" "─")
    print '\x1b[2m\x1b[3m{}\x1b[22m\x1b[23m\n' $table
    return
  end
  if test -z $argv[1]
    if set -q _flag_print
      print '{}' {$HOME}
    else
      cd $HOME >/dev/null
    end
    return
  end


  # Be like simple cd
  if test -d $argv[1]
    cd $argv[1]
    return
  end

  if test -f $HOME/.config/goto.idx
    set -f PATH_INDEX_CONTENT (cat $HOME/.config/goto.idx)
  else
    # Set a default config, but give a warning
    set -f PATH_INDEX_CONTENT \
      'cfg &!HOME;/.config' \
      'ubin /usr/bin' \
      'ulib /usr/lib' \
      'uetc /usr/etc' \
      'dtkp &!HOME;/Desktop' \
      'nvc &*cfg;/nvim'
    print '{f191}[WARN]{r} Index file no found, default aliases are set\n'
  end

  set -l keys (print '{}\n' $PATH_INDEX_CONTENT | grep -Po '^\s*\K[^\s]+')
  set -l alias (print '{}\n' $PATH_INDEX_CONTENT | grep -Po '(?<=\s)[^\s].*(?=$)')

  set -l modifiers $argv[2..-1]
  set -l new_argv $argv[2..-1]
  set -l ent_regex '&(\*|!|%)([^;\s]*);'
  if set -l idx (contains -i $argv[1] $keys[1..-1])
    set -f path $alias[$idx]
  else
    print '{f160}[ERR ]{r} Alias "{}" not found\n' $argv[1]
    return 2
  end

  while set -l rematch (string match --regex $ent_regex $path)
    switch $rematch[2]
      case '\*'
        if set -l idx (contains -i $rematch[3] $keys)
          set path (string replace --all $rematch[1] $alias[$idx]\/ $path)
        else
          print '{f160}[ERR ]{r} Alias "{}" not found\n' $rematch[3]
          return 2
        end
      case '!'
        if set -l var $$rematch[3]
          set path (string replace --all $rematch[1] $var\/ $path)
        else
          print '{f160}[ERR ]{r} Environment variable "{}" inaccessible\n' $rematch[3]
          return 3
        end
      case '%'
        if test -z $modifiers[$rematch[3]]
          print '{f160}[ERR ]{r} Modifiers number "{}" not found\n' $rematch[3]
          return 4
        end
        set path (string replace --all $rematch[1] $modifiers[$rematch[3]]\/ $path)
        set new_argv $new_argv[2..-1]
    end
  end
  # Append every restant item to path, only if it exists & is a folder
  while test (count $new_argv) -gt 0
    if not test -d "$path/$new_argv[1]"
      break
    end
    set path "$path/$new_argv[1]"
    set new_argv $new_argv[2..-1]
  end

  if not test -d $path
    print '{f160}[ERR ]{r} Folder "{}" does not exist or is not accessible\n' $path
    return 7
  end
  if set -q _flag_print
    print '{}\n' (string replace '//' '/' $path)
    return
  end
  cd $path >/dev/null
end

