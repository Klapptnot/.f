# Barg - Bash ARGuments parser
<!-- Documentation for version 1.0.0 -->

## Description
Barg is a Bash argument parser that helps handle command-line arguments in a more structured manner. It allows you to define required and optional arguments, handle different data types, and group related arguments together.

## How to Use It (Example)
Below is an example of how to use Barg in your Bash script:

```bash
barg.parse "${@}" << BARG
#[colored=false, progname=HUMBLE]
#[exit=false, garbage=MY_VAR]
@req (d/download[1] l/list[2] D/dry-run[3] s/serve[4])[switch] => PROCESS
@opt u/user[str] |> ${USER} => username
@opt t/timeout[num] |> 5 => TIMEOUT || R/reason[num] => Reason
@opt H/header[vec[str]] => HEADERS
@grp l/logging[bool] => LOGGING <> (d/debug[1] i/info[2] w/warn[3] e/error[4])[switch] => LOG_LEVEL
BARG
```

## Explanation of the Example Usage
In the example above, the script uses the `args.parse` function to handle command-line arguments. The arguments are defined using a Here Document (<<BARG) to make the syntax more readable.

- `#[key=value,...]`: Indicates configuration parameters
- `@req`: Indicates required arguments (default values are ignored).
- `@opt`: Indicates optional arguments.
- `@grp`: Indicates grouped arguments.

For each argument, the format is: `short/long[data_type] |> [default_value] => VARIABLE`.

- `short`: The short flag (e.g., `-f`) for the argument.
- `long`: The long flag (e.g., `--file`) for the argument.
- `data_type`: The data type of the argument (e.g., `str`, `num`, `int`, `float`, `bool`, or `vec[...]` for a vector, `switch` for defined options).
- `VARIABLE`: The name of the variable that will store the value of the argument.
- `default_value`: (Optional, use `|>` to assign) The default value to use if the argument is not provided.

In the provided example:
- `#[colored=false, progname=HUMBLE]` and `#[exit=false, output=true, garbage=MY_VAR]`: Set configurations for the specified key (see **Configurations**).
- `(d/download[1] l/list[2] D/dry-run[3] s/serve[4])[switch] => PROCESS`: Defines a required argument type `switch`, which sets one of their values to `PROCESS` according to the specified flags from the command line.
- `u/user[str] => username`: Defines an optional argument `-u` or `--user` that expects a string value, with a default value of the content of `${USER}` if not provided, and the value will be stored in the `username` variable.
- `t/timeout[num] |> 5 => TIMEOUT`: Defines an optional argument `-t` or `--timeout` that expects a numerical value (integer or float), with a default value of `5` if not provided. The value will be stored in the `TIMEOUT` variable.
- `H/header[vec[str]] => HEADERS`: Defines an optional argument `-H` or `--header` that expects a vector of strings. The values will be stored in the `HEADERS` array.
- `l/logging[bool] => LOGGING`: Defines an optional argument `-l` or `--logging` that stores a boolean value (`true` or `false`). The value will be stored in the `VERBOSE` variable. Additionally, this argument is grouped with one sub-argument:
    - `(d/debug[1] i/info[2] w/warn[3] e/error[4])[switch] => LOG_LEVEL`: A sub-argument of `-v` that expects one of all the possible values from this switch. The value will be stored in the `LOG_LEVEL` variable.

## **Data Types:**
The `barg.parse` function supports several data types for command-line arguments, enabling you to define various types of options and values that can be passed to your script. Each data type has specific rules for parsing and validation.

**1. `bool`**

The `bool` data type represents a boolean value, which can either be true or false. If the argument is present in the command line, its associated variable will be set to true; otherwise, it will be set to false.

**Example:**

```bash
# Command Line Example:
./script.sh --verbose

# Code Example:
@opt v/verbose[bool] => VERBOSE
```

In this example, the `v` or `verbose` argument is a boolean option. If the user provides `-v` or `--verbose` in the command line, the `VERBOSE` variable will be set to true; otherwise, it will be set to false.

**Usage:**

```bash
if "${VERBOSE}"; then
  # Perform verbose operations
fi
```

**2. `num`**

The `num` data type represents numerical values in general. It can handle both integers and floating-point numbers. When using the `num` data type, you can pass any valid numerical input as an argument.

**Example:**

```bash
# Command Line Example:
./script.sh --number 42

# Code Example:
@opt n/number[num] => NUMBER
```

In this example, the `n` or `number` argument expects a numerical value. The `NUMBER` variable will be set to the provided numerical value, whether it's an integer or a floating-point number.

**Usage:**

```bash
if ((NUMBER > 0)); then
  # Perform actions based on the provided NUMBER
fi
```

**3. `int`**

The `int` data type specifically represents integer values. It allows you to constrain the input to only accept whole numbers (no decimal points).

**Example:**

```bash
# Command Line Example:
./script.sh --count 5

# Code Example:
@opt c/count[int] => COUNT
```

In this example, the `c` or `count` argument expects an integer value. The `COUNT` variable will be set to the provided integer value.

**Usage:**

```bash
for ((i = 0; i < COUNT; i++)); do
  # Loop based on the value of COUNT
done
```

**4. `float`**

The `float` data type represents floating-point values, i.e., numbers that can have decimal points. It allows you to constrain the input to only accept floating-point numbers.

**Example:**

```bash
# Command Line Example:
./script.sh --temperature 25.5

# Code Example:
@opt t/temperature[float] => TEMPERATURE
```

In this example, the `t` or `temperature` argument expects a floating-point value. The `TEMPERATURE` variable will be set to the provided floating-point number.

**Usage:**

```bash
if ((TEMPERATURE < 0.0)); then
  # Take actions for sub-zero temperatures
elif ((TEMPERATURE >= 0.0 && TEMPERATURE <= 100.0)); then
  # Take actions for temperatures between 0 and 100 degrees Celsius
else
  # Take actions for temperatures above 100 degrees Celsius
fi
```

**Constraints and Validation:**

When using the `num`, `int`, or `float` data types, you can specify additional constraints or validation rules to ensure the input meets your requirements. For instance, you can set a minimum and maximum value, or you can define a default value to be used if no argument is provided.

**Example:**

```bash
# Command Line Example (with default value):
./script.sh --timeout

# Code Example (with constraints):
@opt t/timeout[num] |> 5 => TIMEOUT
```

In this example, the `t` or `timeout` argument expects a numerical value. The `TIMEOUT` variable will be set to the provided value, but if no value is provided (like in the command line example), it will default to 5 due to the specified constraint (`|> 5`).

**Usage:**

```bash
if ((TIMEOUT > 0)); then
  # Perform actions with TIMEOUT (which is either user-provided or defaults to 5)
fi
```

By using these numerical data types and constraints, you can ensure that the input received from command-line arguments is properly validated and conforms to your script's requirements, providing a more robust and reliable experience for users.

**3. `str`**

The `str` data type represents a string value. It allows you to pass any arbitrary string as an argument.

**Example:**

```bash
# Command Line Example:
./script.sh --name JohnDoe

# Code Example:
@opt n/name[str] => NAME
```

In this example, the `n` or `name` argument expects a string value. The `NAME` variable will be set to the provided string.

**Usage:**

```bash
echo "Hello, ${NAME}!"
```

**5. `vec` (Vector):**

The `vec` data type represents a list of values of the specified data type. It allows you to pass multiple values separated by commas for an argument.

**Example:**

```bash
# Command Line Example:
./script.sh -p 10 -p 20 -p 30

# Code Example:
@opt p/price[vec[int]] => PRICES
```

In this example, the `p` or `price` argument expects a list of integer values separated by commas. The `PRICES` variable will be set to an array containing the provided integer values.

**Usage:**

```bash
for price in "${PRICES[@]}"; do
  # Process each price in the PRICES array
done
```

**6. `switch`**

The `switch` data type allows you to create a command-line argument that acts like a boolean, but instead of using `true` or `false`, it takes multiple possible values defined inside brackets. When any of these values are specified in the command line, the variable associated with the `switch` will be set to the corresponding value. If none of the specified values are found, the variable will be set to a default value (usually 0).

**Example:**

```bash
# Command Line Example:
./script.sh -D

# Code Example:
@opt (d/download[1] l/list[2] s/serve[3])[switch] => PROCESS
# Also works this way, but it's redundant (better: P/process[int] |> 0 => PROCESS)
# @opt (1[1] 1[2] 3[3])[switch] => PROCESS
# And it should accept "-1", "-2", and so on
```

In this example, we have a `switch` called `PROCESS`, which can take the values 1, 2, 3, or 4. Each value corresponds to a specific action that the script should take. If any of the specified values are found in the command line, the `PROCESS` variable will be set accordingly. If none of the values are found, the default value (0) will be set.

**Usage in a Case Statement:**

```bash
case "${PROCESS}" in
  1)
    # Action for download
    ;;
  2)
    # Action for list
    ;;
  3)
    # Action for serve_content
    ;;
  0)
    # Action when no value is passed (default case)
    ;;
esac
```

In this case statement, we check the value of the `PROCESS` variable and execute different actions based on its value. If the `PROCESS` variable is set to 1, the script will execute the download action. If it's set to 2, the script will execute the list action, and so on. If none of the values are found, the script will execute the default action (case 0).

## **The Diamond Operator `<>`**

The diamond operator (`<>`) in Barg is (used as) a powerful tool for selectively processing arguments based on the presence or absence of a root argument. It allows conditional assignment of values to variables, providing a convenient way to set default values for certain arguments when a specific root argument is not provided, ignoring them even if they are present in the command line.

**Example:**

```bash
# Command Line Example:
./script.sh -v
```

**Code Example:**

```bash
@grp l/logging[bool] => LOGGING <> (d/debug[1] i/info[2] w/warn[3] e/error[4])[switch] => LOG_LEVEL
```

In this example, `l` or `logging` is the root argument, and it is of type `bool` (boolean). If the root argument `-l` or `--logging` is present in the command-line input, the script will process the arguments specified to the right of the diamond operator (`<>`). Otherwise, the script will assign default values to the arguments on the right.

**Usage:**

The diamond operator is helpful in scenarios where you want to enable certain features or actions only when a particular root argument is provided. It allows you to control the behavior of the script based on whether the root argument is set or not.

```bash
if ${LOGGING}; then
  # Perform actions for logging mode (when -l or --logging is passed)
else
  # Action to do when logging mode is false (when -l or --logging is not passed)
fi
```

**Explanation:**

1. When `./script.sh -l` is executed, the `LOGGING` variable will be set to `true`, and the script will process the arguments `d/debug`, `i/info`, `w/warn` and `e/error` from `switch`.

2. If `./script.sh` is executed without the `-l` flag (i.e., `./script.sh`), the `LOGGING` variable will be set to its default value (if any), and the arguments from `switch` will not be processed or checked (`switch` default is 0).

3. If `./script.sh -d` or `./script.sh -i` (or any flag from the `switch`) is executed, the script will ignore them because the root argument `-l` or `--logging` is not present.

4. If `./script.sh -v -d` or `./script.sh -v -i` (`-v` with any flag from the `switch`) is executed, the `LOGGING` variable will be set to `true`, and the script will process the flags from `switch` from the command-line.

The diamond operator allows you to create a conditional flow in your script, where specific actions or default values are applied based on whether a certain root argument is passed on the command line. It enhances the flexibility and usability of your script by enabling users to enable or disable certain functionalities based on their needs.

## **Configurations**

The `barg.parse` function provides several configuration settings that allow you to customize its behavior while reading command-line arguments or when an error occurs. These configurations can be set using specific syntax in the script, and they control various aspects of the parsing process.

Below are the configuration settings along with their names and default values:

1. `colored` (Default: true)
   - Description: Determines whether colored output is enabled or not.
   - Usage: `#[colored='false']`

2. `exit` (Default: true)
   - Description: Controls whether the script exits on an error or returns without terminating.
   - Usage: `#[exit='false']`

3. `output` (Default: true)
   - Description: Specifies whether the script should print output or not.
   - Usage: `#[output='true']`

4. `progname` (Default: BARG)
   - Description: Sets the program name used in the error messages (Will always be printed in uppercase).
   - Usage: `#[progname='my program']`

5. `errvar` (Default: null)
   - Description: If specified, sets the error data to a variable with the name equal to the value of `errvar`. This configuration is ignored when `output` is false.
   - Usage: `#[errvar='ERROR_VAR']`

6. `garbage` (Default: null)
   - Description: Appends the garbage values passed through the command line (e.g., `script -- iykyk` or `script -- "idk lol"`) to an array with the name equal to the value of `garbage`. When `null`, this feature is disabled.
   - Usage: `#[garbage='MY_VAR']`

7. `stderr` (Default: true)
   - Description: Determines whether the error messages should be printed to the standard error (stderr) stream.
   - Usage: `#[stderr='false']`

**Usage example:**
```bash
barg.parse "${@}" <<EOL
#[colored='false', progname='awesome']
#[stderr='false']
@opt ... => ...
EOL
```

**NOTE:**
The value passed inside the #[...] must *ALWAYS* be quoted with single quotes

**Explanation:**

You can modify the behavior of `barg.parse` by including configuration settings in your script using the `#[config_name=value]` syntax. Each configuration has a default value that will be used if not explicitly set in the script. These settings allow you to control aspects such as colored output, error handling, output printing, error variable assignment, and garbage value handling.

For example, to disable colored output, you can add `#[colored=false]` in your script. Similarly, to change the program name used in error messages to "HUMBLE," you can include `#[progname="HUMBLE"]`. If you wish to handle errors manually and prevent the script from exiting on error, you can set `#[exit='false']`.

By customizing these configuration settings, you can tailor the behavior of `barg.parse` to suit your specific needs, making the command-line argument parsing process more flexible and user-friendly.

## How the Code Works, What It Does
The `args.parse` function is the main part of the code. It takes the command-line arguments (`"${@}"`) as input and parses them according to the defined argument structure provided as a Here Document (`<<BARG`). The function iterates through the arguments, identifies the data type and default values, and assigns the corresponding values to the specified variables.

- The `arg.define` function is a helper function that processes each argument definition in the Here Document. It validates the argument data type, checks for default values, and sets the specified variables accordingly.

- The `args.barg_highlighter` function is another helper function that handles the formatting and coloring of the argument definitions to make them more visually appealing and distinguishable.

- The `exit_now_msg` function is used to handle error messages and exit codes in case of invalid or missing arguments.

## Exit Codes
The script uses different exit codes to indicate various types of errors encountered during argument parsing:

- `11`: Failed bracket operation AND (Not enough arguments).
- `12`: Failed bracket operation OR (More arguments than needed).
- `13`: Invalid syntax (Diamond operator used incorrectly).
- `14`: Data type mismatch (Expected a different data type).
- `15`: Invalid numerical value.

## Notes
- Barg is a powerful tool for parsing command-line arguments in a structured manner, making it easier to handle complex argument requirements.
- Be careful with the argument definitions and their corresponding data types to avoid unexpected behavior.
- The script checks for valid numerical values and reports errors if the input does not match the expected format.
- Always provide meaningful default values for optional arguments to ensure graceful handling when they are not provided in the command line.

**(Note: The provided documentation may be subject to updates or changes based on the actual usage and requirements.)**
