#! /bin/bash

# Barg - Bash ARGuments parser
# ============================

# Check if this script is being executed as the main script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Break execution
  printf "[\x1b[38;05;160m*\x1b[00m] This script is not made to run as a normal script\n"
  exit 1
fi

function barg.parse() {
  local argv=("${@}")
  [ "${#argv[@]}" -eq 0 ] && return 1
  # Expand the joint arguments
  function barg.normalize_args() {
    for ((i = 0; i < ${#argv[@]}; i++)); do
      #* Joint parameters
      # Example 1:
      # 	Short for --lenght is -l, so --lenght 10 can be
      # 		-l 10
      # 		-l10
      # For this (-l10) to work properly, with all the checks
      # we need to split the parameter and reasign
      # the parameter and value to argv
      #
      # Example 2:
      #	Short for parameter --get is -g, and for --all is -a
      # 		-ga
      # 		-ag
      # With this, we need to reasign argv with the short parameters
      # for each parameter: -${char}
      # So it can hold a long list of short parameters
      # We need to check that all characters are letters, otherwise
      # we would have to use them as a value... NO
      #
      # Here we need to modify the the argv array, so we need to break
      # and restart the for loop to make sure that the argv array
      # length is consistent
      if [[ "${argv[i]}" != -* ]] || [ "${#argv[i]}" -eq 2 ] || [[ "${argv[i]}" == --* ]]; then
        continue
      fi
      if [[ "${argv[i]}" =~ ^-[A-Za-z][0-9_\.]*$ ]]; then # only -t2 (argument and numeric value)
        argv=(
          "${argv[@]:0:i}"           # All before joint argument
          "${argv[i]:0:2}"           # the short argument key
          "${argv[i]:2:${#argv[i]}}" # The content of the argument
          "${argv[@]:(i + 1)}"       # All after joint argument
        )
      else #if [[ "${argv[i]}" =~ ^-[A-Za-z]*$ ]]; then # only -ag, -us4 or -hj (flags)
        # argv[i]="${argv[i]:1}"
        # This works with shopt -s patsub_replacement
        # read -ra __slices__ <<<"${argv[i]//?/-&\ }"
        local __slices__=()
        while read -rn 1 char; do
          __slices__+=("-${char}")
        done <<< "${argv[i]:1}"
        if [[ "${#__slices__[@]}" -gt 0 ]]; then
          argv=(
            "${argv[@]:0:i}"                             # All before joint argument
            "${__slices__[@]:0:(${#__slices__[@]} - 1)}" # All individual argument
            "${argv[@]:(i + 1)}"                         # All after joint argument
          )
        fi
        unset __slices__
      fi
    done
  }

  function barg.set_indices_to_empty() {
    for index in "${@}"; do
      if ((index >= 0 && index < ${#BARG_EXTRAS_BEFORE[@]})); then
        BARG_EXTRAS_BEFORE[index]=""
      fi
    done
  }

  # barg.define "${arg_pat}" "${var_name}" "${def_val}" "${arg_type}" "${vec_type}" "${switch_pat}" "${__ignore__}"
  function barg.define() {
    local __pat__="${1}" # short/long[...]
    local __var__="${2}" # VARIABLE (variable name)
    local __val__="${3}" # Variable default value
    local __typ__="${4}" # Variable value type
    local __vec__="${5}" # Vector variable value type
    local __swi__="${6}" # Switch Pattern
    local __ign__="${7}" # Ignore command line value and set default if available

    if [[ "${__typ__}" == "vec[bool]" ]]; then
      echo "${__typ__}"
      barg.exit "Invalid data type in '${__pat__}'" "A vector of bool is not a valid data type" 17
    fi

    # To test whether a variable is defined
    # > ! declare -p "${__var__}" &>/dev/null
    # > test -n "${__var__@A}" or [ -n "${__var__@A}" ]
    # Both have the same output (for example: foo="bar" or declare -r foo="baz")
    # Preferably @A, no error is returned, but bash redirection is needed here
    # > test -n "${!__var__@A}"
    # In declare -p '${__var__}', bash replaces the variable name
    # To set the variable, use declare -g "${__var__}=${content}"

    if [ -n "${__swi__}" ]; then
      local STR="${__swi__}"
      while [[ "${STR}" =~ ${__swi_regex__} ]]; do
        # local full_match="${BASH_REMATCH[1]}"
        local short="${BASH_REMATCH[2]}"
        local long="${BASH_REMATCH[3]}"
        local value="${BASH_REMATCH[5]:-${BASH_REMATCH[7]}}"
        local items="${!_argv_table[*]}"

        if [[ "${items}" == *"-${short}"* ]]; then
          [ -z "${!__var__@A}" ] && declare -g "${__var__}=${value}"
          barg.set_indices_to_empty $((${_argv_table["-${short}"]} - 1))
          unset "_argv_table[-${short}]"
        elif [[ "${items}" == *"--${long}"* ]]; then
          [ -z "${!__var__@A}" ] && declare -g "${__var__}=${value}"
          barg.set_indices_to_empty $((${_argv_table["-${long}"]} - 1))
          unset "_argv_table[--${long}]"
        fi

        STR="${STR/#"${BASH_REMATCH[0]}"/}"
      done
      if ! ${__ign__} && [ -n "${!__var__@A}" ]; then
        return 0
      fi
      declare -g "${__var__}=${__val__:-0}"
      return 2
    fi

    #shellcheck disable=2178
    local __key__="${__pat__%%[*}"
    local __short__="${__key__%/*}"
    local __long__="${__key__#*/}"

    if [ -n "${_argv_table["-${__short__}"]}" ]; then
      local _table_item="-${__short__}"
    elif [ -n "${_argv_table["--${__long__}"]}" ]; then
      local _table_item="--${__long__}"
    else
      # Set default value
      if [ "${__typ__}" == "bool" ]; then
        declare -g "${__var__}=false"
        return 2
      fi
      if [ -n "${__val__}" ]; then
        declare -g "${__var__}=${__val__}"
        return 2
      fi
      return 1
    fi

    local __rm_arg__=true
    case "${__typ__}" in
      'bool')
        [ -z "${!__var__@A}" ] && declare -g "${__var__}=true"
        barg.set_indices_to_empty $((${_argv_table[${_table_item}]} - 1))
        unset "_argv_table[${_table_item}]"
        __rm_arg__=false
        ;;
      'vec'*)
        local _current_indexes=()
        IFS=',' read -ra _current_indexes <<< "${_argv_table[${_table_item}]}"
        for index in "${_current_indexes[@]}"; do
          [ -z "${argv[index]}" ] && continue
          if [ "${__vec__}" == "num" ] && ! [[ "${argv[index]}" =~ ${__num_regex__} ]]; then # Not an valid num...
            if [[ "${argv[index]}" =~ ^[_\.0-9]*$ ]]; then                                   # but could be a num?
              barg.exit "Unknown NUM format: ${argv[index]}" "Invalid numerical value, expected a int or float" 15
            fi
            barg.exit "Type mismatch: Not NUM (${argv[index]})" "Expected a int or float, got a string" 14
          elif [ "${__vec__}" == "int" ] && ! [[ "${argv[index]}" =~ ${__int_regex__} ]]; then # Not an valid int...
            if [[ "${argv[index]}" =~ ^[_\.0-9]*$ ]]; then                                     # but could be a int?
              barg.exit "Unknown NUM format: ${argv[index]}" "Invalid numerical value, expected a integer" 15
            fi
            barg.exit "Type mismatch: Not INT (${argv[index]})" "Expected a int, got a string" 14
          elif [ "${__vec__}" == "float" ] && ! [[ "${argv[index]}" =~ ${__flt_regex__} ]]; then # Not an valid float...
            if [[ "${argv[index]}" =~ ^[_\.0-9]*$ ]]; then                                       # but could be a float?
              barg.exit "Unknown NUM format: ${argv[index]}" "Invalid numerical value, expected a float" 15
            fi
            barg.exit "Type mismatch: Not FLOAT (${argv[index]})" "Expected a float, got a string" 14
          fi
          case "${argv[index]}" in
            '---')
              if [ "${__vec__}" == 'str' ]; then
                declare -ga "${__var__}+=(\"${argv[index + 1]}\")"
              else
                declare -ga "${__var__}+=(\"${argv[index + 1]//_/}\")"
              fi
              ;;
            '-'*)
              local err_str="${argv[*]:(index - 1):(index + 1)}"
              barg.exit "Param-like value: ${err_str}" "Value for '${argv[(index - 1)]}' looks like an option/flag. Use '--- ${argv[index]}' to bypass" 18
              ;;
            *)
              if [ "${__vec__}" == 'str' ]; then
                declare -ga "${__var__}+=(\"${argv[index]}\")"
              else
                declare -ga "${__var__}+=(\"${argv[index]//_/}\")"
              fi
              ;;
          esac
        done
        unset "_current_indexes"
        ;;
      'num')
        if ! [[ "${argv[${_argv_table[${_table_item}]}]}" =~ ${__num_regex__} ]]; then # Not an valid num...
          if [[ "${argv[${_argv_table[${_table_item}]}]}" =~ ^[_\.0-9]*$ ]]; then      # but could be a num?
            barg.exit "Unknown NUM format: ${argv[${_argv_table[${_table_item}]}]}" "Invalid numerical value, expected a int or float" 15
          fi
          barg.exit "Type mismatch: Not NUM (${argv[${_argv_table[${_table_item}]}]})" "Expected a int or float, got a string" 14
        fi
        case "${argv[${_argv_table[${_table_item}]}]}" in
          '---')
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[(${_argv_table[${_table_item}]} + 1)]//_/}"
            ;;
          '-'*)
            local err_str="${argv[*]:(${_argv_table[${_table_item}]} - 1):(${_argv_table[${_table_item}]} + 1)}"
            barg.exit "Param-like value: ${err_str}" "Value for '${argv[(${_argv_table[${_table_item}]} - 1)]}' looks like an option/flag. Use '--- ${argv[${_argv_table[${_table_item}]}]}' to bypass" 18
            ;;
          *)
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[${_argv_table[${_table_item}]}]//_/}"
            ;;
        esac
        ;;
      'int')
        if ! [[ "${argv[${_argv_table[${_table_item}]}]}" =~ ${__int_regex__} ]]; then # Not an valid int...
          if [[ "${argv[${_argv_table[${_table_item}]}]}" =~ ^[_\.0-9]*$ ]]; then      # but could be a int?
            barg.exit "Unknown NUM format: ${argv[${_argv_table[${_table_item}]}]}" "Invalid numerical value, expected a integer" 15
          fi
          barg.exit "Type mismatch: Not INT (${argv[${_argv_table[${_table_item}]}]})" "Expected a int, got a string" 14
        fi
        case "${argv[${_argv_table[${_table_item}]}]}" in
          '---')
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[(${_argv_table[${_table_item}]} + 1)]//_/}"
            ;;
          '-'*)
            local err_str="${argv[*]:(${_argv_table[${_table_item}]} - 1):(${_argv_table[${_table_item}]} + 1)}"
            barg.exit "Param-like value: ${err_str}" "Value for '${argv[(${_argv_table[${_table_item}]} - 1)]}' looks like an option/flag. Use '--- ${argv[${_argv_table[${_table_item}]}]}' to bypass" 18
            ;;
          *)
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[${_argv_table[${_table_item}]}]//_/}"
            ;;
        esac
        ;;
      'float')
        if ! [[ "${argv[${_argv_table[${_table_item}]}]}" =~ ${__flt_regex__} ]]; then # Not an valid float...
          if [[ "${argv[${_argv_table[${_table_item}]}]}" =~ ^[_\.0-9]*$ ]]; then      # but could be a float?
            barg.exit "Unknown NUM format: ${argv[${_argv_table[${_table_item}]}]}" "Invalid numerical value, expected a float" 15
          fi
          barg.exit "Type mismatch: Not FLOAT (${argv[${_argv_table[${_table_item}]}]})" "Expected a float, got a string" 14
        fi
        case "${argv[${_argv_table[${_table_item}]}]}" in
          '---')
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[(${_argv_table[${_table_item}]} + 1)]//_/}"
            ;;
          '-'*)
            local err_str="${argv[*]:(${_argv_table[${_table_item}]} - 1):(${_argv_table[${_table_item}]} + 1)}"
            barg.exit "Param-like value: ${err_str}" "Value for '${argv[(${_argv_table[${_table_item}]} - 1)]}' looks like an option/flag. Use '--- ${argv[${_argv_table[${_table_item}]}]}' to bypass" 18
            ;;
          *)
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[${_argv_table[${_table_item}]}]//_/}"
            ;;
        esac
        ;;
      'str')
        case "${argv[${_argv_table[${_table_item}]}]}" in
          '---')
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[(${_argv_table[${_table_item}]} + 1)]}"
            ;;
          '-'*)
            local err_str="${argv[*]:(${_argv_table[${_table_item}]} - 1):(${_argv_table[${_table_item}]} + 1)}"
            barg.exit "Param-like value: ${err_str}" "Value for '${argv[(${_argv_table[${_table_item}]} - 1)]}' looks like an option/flag. Use '--- ${argv[${_argv_table[${_table_item}]}]}' to bypass" 18
            ;;
          *)
            [ -z "${!__var__@A}" ] && declare -g "${__var__}=${argv[${_argv_table[${_table_item}]}]}"
            ;;
        esac
        ;;
    esac

    # Let items empty in BARG_EXTRAS
    # Not removing them to keep same lenght same index
    if ${__rm_arg__}; then
      local new_idxs=()
      IFS=',' read -ra _current_indexes <<< "${_argv_table[${_table_item}]}"
      for i in "${_current_indexes[@]}"; do
        new_idxs+=("$((i - 1))")
      done
      barg.set_indices_to_empty "${_current_indexes[@]}" "${new_idxs[@]}"
      unset "new_idxs"
      unset "_current_indexes"
      unset "_argv_table[${_table_item}]"
    fi

    if ${__ign__}; then
      if [ "${__typ__}" == "bool" ]; then
        declare -g "${__var__}=false"
        return 2
      fi
      if [ -n "${__val__}" ]; then
        declare -g "${__var__}=${__val__}"
        return 2
      fi
    fi

    [ -n "${!__var__@A}" ] && return 0

    # Set default value
    if [ "${__typ__}" == "bool" ]; then
      declare -g "${__var__}=false"
      return 2
    fi

    if [ -n "${__val__}" ]; then
      declare -g "${__var__}=${__val__}"
      return 2
    fi

    return 1
  }

  # barg.exit <error name> <error desc>
  # shellcheck disable=SC2154
  function barg.exit() {
    local colored=${__barg_opts__[colored]}
    local stderr=${__barg_opts__[stderr]}
    local output=${__barg_opts__[output]}
    local errvar=${__barg_opts__[errvar]}
    local progname=${__barg_opts__[progname]}
    local exit=${__barg_opts__[exit]}

    local error_type="${1:-null}"
    local error_desc="${2:-null}"

    local __err__="${error_type}\n\x1b[38;05;160m[${progname}> ERROR] ${error_desc}\x1b[00m"
    [ "${colored}" != 'true' ] && __err__="${error_type}\n[${progname}> ERROR] ${error_desc}"

    if [ "${output}" == 'true' ]; then
      [ "${stderr}" == 'true' ] && printf '%b\n' "${__err__}" >&2 ||
        printf '%b\n' "${__err__}"
    fi

    if [ "${errvar:-NULL}" != 'null' ] && [ "${output}" == 'true' ]; then
      declare -g "${errvar}=${error_type}\n${error_desc}\n${3:-null}"
    fi

    local exit_code="${3:-1}"
    # Exit early if error is from options, or return
    if [ "${exit_code}" -lt 20 ] && [ "${exit}" != 'true' ]; then
      return "${exit_code}"
    fi

    exit "${exit_code}"
  }

  # Int or float
  local __num_regex__='^((-?[0-9]{1,3}(_[0-9]{3})*|-?[0-9]*)|(-?[0-9]{1,3}(_[0-9]{3})+\.([0-9]{3}(_[0-9]{1,3})*|[0-9]{1,3})|-?[0-9]+\.[0-9]+))$'
  local __int_regex__='^(-?[0-9]{1,3}(_[0-9]{3})*|-?[0-9]*)$'
  local __flt_regex__='^(-?[0-9]{1,3}(_[0-9]{3})+\.([0-9]{3}(_[0-9]{1,3})*|[0-9]{1,3})|-?[0-9]+\.[0-9]+)$'
  local __opt_regex__='(,|#\[)\ *([A-Za-z_][_A-Za-z0-9]+?)=|"(([^"\\]|\\.)*)"\]?|'\''(([^'\''\\]|\\.)*)'\''\]?'
  # shellcheck disable=SC1003
  local __def_regex__='\s*(\|\||&&|<>)?\s*(!)?\s*(@[a-zA-Z0-9\-_]+)?\s*([A-Za-z0-9!?@#_.:<>]?/?[A-Za-z0-9!?@#_.:<>\-]+\[(str|float|int|num|bool|vec\[(str|float|int|num|bool)\])\]|\{((\s*[A-Za-z0-9!?@#_.:<>]?/?[A-Za-z0-9!?@#_.:<>\-]+\s*=>\s*("((\\"|[^"])*?)"|'\''((\\'\''|[^'\''])*?)'\'')\s*)+)\})\s*(\|>\s*("((\\"|[^"])*?)"|'\''((\\'\''|[^'\''])*?)'\''))?\s*=>\s*([a-zA-Z][a-zA-Z0-9_]*)' #(\s*("((\\"|[^"])*?)"|'\''((\\'\''|[^'\''])*?)'\''))?'
  # shellcheck disable=SC1003
  local __swi_regex__='\s*(([A-Za-z0-9!?@#_.:<>])/([A-Za-z0-9!?@#_.:<>\-]+)\s*=>\s*("((\\"|[^"])*?)"|'\''((\\'\''|[^'\''])*?)'\''))\s*'

  local __line__=1
  declare -A __barg_opts__=(
    [colored]=true     # Enable colored output (default: true)
    [output]=true      # Print output to the console (default: true)
    [stderr]=true      # Redirect output to standard error (default: true)
    [exit]=true        # Exit the script on error (instead of returning an error code)
    [reqextras]=false  # Treat positional arguments as required (default: false)
    [subcmdr]=false    # Require a subcommand to be specified (default: false)
    [subcmds]=''       # Comma-separated list of valid subcommands (default: empty)
    [emptycheck]=false # Allow required values to be zero-length (default: false)
    [progname]='BARG'  # Program name to use in error messages (default: 'BARG')
    [errvar]=null      # Variable name to store error data in (default: null)
    [extras]=null      # Collect positional parameters (default: null)
  )
  barg.normalize_args # Normalize joint arguments, from '-abc' to '-a -b -c'
  local BARG_EXTRAS_BEFORE=("${argv[@]}")
  declare -A _argv_table
  for ((i = 0; i < ${#argv[@]}; i++)); do
    # ignore values
    [[ "${argv[i]}" != -* ]] && continue
    # If not set, simply add
    if [ -z "${_argv_table[${argv[i]}]}" ]; then
      _argv_table[${argv[i]}]=$((i + 1))
      continue
    fi
    # Append comma separated for vec[any]
    _argv_table[${argv[i]}]="${_argv_table[${argv[i]}]},$((i + 1))"
  done

  local __ilegal_var_names__=(
    BASH BASH_ENV BASH_SUBSHELL BASHPID BASH_VERSINFO BASH_VERSION CDPATH
    DIRSTACK EDITOR EUID FUNCNAME GLOBIGNORE GROUPS HOME HOSTNAME
    HOSTTYPE IFS IGNOREEOF LC_COLLATE LC_CTYPE LINENO MACHTYPE OLDPWD
    OSTYPE PATH PIPESTATUS PPID PROMPT_COMMAND PS1 PS2 PS3 PS4 PWD
    REPLY SECONDS SHELLOPTS SHLVL TMOUT UID
  )

  local STR=""
  while read -r line; do
    # Change the default value for all given options
    if [[ "${line}" == '#['*']' ]]; then
      local __optkey__=""
      local STR="${line}"
      while [[ ${STR} =~ ${__opt_regex__} ]]; do
        if [ -n "${BASH_REMATCH[2]}" ]; then
          __optkey__="${BASH_REMATCH[2]}"
        else
          # 3 is single quote, otherwise 5 for double quote
          if [[ " ${!__barg_opts__[*]} " != *" ${__optkey__} "* ]]; then
            barg.exit "Invalid option: Not found" "Option '${__optkey__}' does not exist" 20
          fi
          __barg_opts__[${__optkey__}]="${BASH_REMATCH[3]:-${BASH_REMATCH[5]}}"
        fi
        # Escapes in string must be escaped, and the # too
        STR="${STR/#"${BASH_REMATCH[0]//\\/\\\\}"/}"
      done
      unset __optkey__
      unset STR
      continue
    fi
    [[ "${line}" == '//'* ]] && continue
    STR+="${line}"$'\n'
  done

  BARG_SUBCOMMAND=""
  # Try to get the possible sub command
  if [ -n "${__barg_opts__[subcmds]}" ] && [[ "${__barg_opts__[subcmds]//,/\ }" == *"${argv[0]}"* ]]; then
    BARG_SUBCOMMAND="${argv[0]}"
  fi
  if [ "${__barg_opts__[subcmdr]}" == "true" ] && [ -n "${__barg_opts__[subcmds]}" ] && [ -z "${BARG_SUBCOMMAND}" ]; then
    barg.exit "Missing subcommand, expected one of ${__barg_opts__[subcmds]//,/,\ }" "A subcommand is required, but none was provided" 21
  fi

  local __ignore__=false
  local __grpsts__=''
  local __status__=''
  local __required__=false
  local last=""
  local __last_sig=""
  local __defer_error=()
  while true; do
    if [[ "${STR}" =~ ${__def_regex__} ]]; then
      STR="${STR/#"${BASH_REMATCH[0]}"/}"
    else
      # If a required has no args, check first if a opr will be used with it
      if [ "${#__defer_error}" -gt 0 ] && [ -z "${log_opr}" ]; then
        barg.exit "${__defer_error[@]}"
      fi
      break
    fi

    if [ "${BASH_REMATCH[0]}" == "${last}" ]; then
      barg.exit "Invalid syntax: Somewhere before ${last}" "Not able to continue reading statements" 67
    fi
    last="${BASH_REMATCH[0]}"

    local log_opr="${BASH_REMATCH[1]}"                        # ?-> Operation (||, &&, <>)
    local arg_lvl="${BASH_REMATCH[2]}"                        # ?-> Is required?????
    local arg_par="${BASH_REMATCH[3]}"                        # ?-> Arg father (sub command)
    local arg_pat="${BASH_REMATCH[4]}"                        # |-> Pattern
    local arg_type="${BASH_REMATCH[5]}"                       # |-> Data type
    local vec_type="${BASH_REMATCH[6]}"                       # ?-> Vec of
    local switch_pat="${BASH_REMATCH[7]}"                     # ?-> Switch options
    local def_val="${BASH_REMATCH[16]:-${BASH_REMATCH[18]}}"  # ?-> Default value
    local var_name="${BASH_REMATCH[20]}"                      # |-> Variable name
    # local def_desc="${BASH_REMATCH[23]:-${BASH_REMATCH[25]}}" # ?-> Def description

    local subcmd_prop="${arg_par:1}"

    # skip options for a distinct sub command
    if [ -n "${subcmd_prop}" ] && [ "${subcmd_prop}" != "${BARG_SUBCOMMAND}" ]; then
      continue
    fi

    # If a @req has no args, check first if a opr will be used with it
    if [ "${#__defer_error}" -gt 0 ] && [ -z "${log_opr}" ]; then
      barg.exit "${__defer_error[@]}"
    fi
    __defer_error=()

    [ "${arg_lvl}" == "!" ] && __required__=true

    if [[ " ${__ilegal_var_names__[*]} " == *" ${var_name} "* ]]; then
      barg.exit "Ilegal name: ${var_name}" "'${var_name}' is an reserved variable name." 78
    fi

    if [ "${log_opr}" == "<>" ]; then
      if [ -z "${__status__}" ]; then
        barg.exit "Ilegal operation: Unparented <>" "The <> was used without a parent definition" 43
      fi
      if [ -z "${__grpsts__}" ]; then
        __grpsts__=${__status__}
      fi
      ${__grpsts__} && __ignore__=false || __ignore__=true
    else
      __ignore__=false
      __grpsts__=''
    fi

    local def_set=false
    local last_run=false
    # shellcheck disable=SC2015
    barg.define "${arg_pat}" "${var_name}" "${def_val}" "${arg_type}" "${vec_type}" "${switch_pat}" "${__ignore__}" &&
      last_run=true
    [ ${?} == 2 ] && def_set=true

    # Default values are not useful in required
    if ${__required__} && ${def_set}; then
      def_set=false
      last_run=false
      unset "${var_name}"
    fi

    # Is empty but was defined
    ${__barg_opts__[emptycheck]} && [ "${!var_name@A}" == "${var_name}=''" ] && last_run=false

    #shellcheck disable=2178
    if [[ "${arg_pat}" != "{"*"}" ]]; then
      local _na="${arg_pat%%[*}"
      if [ "${_na%/*}" == "${_na#*/}" ]; then
        local signat="\x1b[38;5;50m--${_na#*/}\x1b[0m"
      else
        local signat="\x1b[38;5;50m-${_na%/*}\x1b[0m\x1b[38;5;60m/\x1b[0m\x1b[38;5;50m--${_na#*/}\x1b[0m"
      fi
    else
      signat="\x1b[38;5;50m{...switch<${var_name}>}\x1b[0m"
    fi

    if [ -n "${__status__}" ]; then
      if ${__required__}; then
        if [ "${log_opr}" == "&&" ]; then
          if ! [[ ${__status__} && ${last_run} ]]; then
            barg.exit "Failed AND operation: Not enough arguments" "${signat} requires ${__last_sig}" 111
          fi
        elif [ "${log_opr}" == "||" ]; then
          if ${__status__} && ${last_run}; then
            ${def_set} && continue
            barg.exit "Failed OR operation: More arguments than needed" "${signat} is not compatible with ${__last_sig}" 112
          elif ! ${__status__} && ! ${last_run}; then
            ${def_set} && continue
            barg.exit "Failed OR operation: ${signat} OR ${__last_sig} needed" "At least one required argument must exist" 113
          fi
        elif [ -z "${!var_name@A}" ]; then
          __defer_error=("Missing arguments: ${signat} needed" "All required arguments must exist" 113)
        fi
      else
        if [ "${log_opr}" == "&&" ]; then
          if ! [[ ${__status__} && ${last_run} ]]; then
            barg.exit "Failed AND operation: Not enough arguments" "${signat} requires ${__last_sig}" 111
          fi
        elif [ "${log_opr}" == "||" ]; then
          if ${__status__} && ${last_run}; then
            ${def_set} && continue
            barg.exit "Failed OR operation: More arguments than needed" "${signat} is not compatible with ${__last_sig}" 112
          fi
        fi
      fi
    elif [ -z "${!var_name@A}" ]; then
      __defer_error=("Missing arguments: ${signat} needed" "All required arguments must exist" 113)
    fi

    __status__=${last_run}
    __last_sig="${signat}"
  done

  # String that is non-zero lenght after being striped
  # should mean that regex was not able to match...
  # because it's not available and not because the user made some mistakes
  if [ -n "${STR}" ]; then
    STR="${STR//$'\n'/}"
    STR="${STR//\ /}"
    if [ -n "${STR}" ]; then
      barg.exit "Regex error: No match" "BASH version may not support some regex functions" 2
    fi
  fi

  for item in "${BARG_EXTRAS_BEFORE[@]}"; do
    if [[ -n "${item}" ]]; then
      declare -a "BARG_EXTRAS+=(\"${item}\")"
    fi
  done

  if ${__barg_opts__[reqextras]} && [ "${#BARG_EXTRAS[@]}" -eq 0 ]; then
    barg.exit "Missing extra arguments: Zero items found" "At least 1 unnamed/extra argument is required" 120
  fi

  local grbg="${__barg_opts__[extras]}"
  if [ 'null' != "${grbg:-null}" ]; then
    # shellcheck disable=SC2145
    declare -ga "${grbg}=(${BARG_EXTRAS[*]@Q})"
  else
    declare -ga BARG_EXTRAS=("${BARG_EXTRAS[@]}")
  fi

}
