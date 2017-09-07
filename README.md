# TouK bash

Bash scripts we use at TouK for our daily development.

## Modules

These are modules you can copy and use it in your scripts:

#### touk-bash-core

This is a main part and it's required by other modules. Functions:

- *exe* - Output a command, execute it and exit if it has failed
- *quietExe* - Execute a command without printing it and exit if it has failed
- *confirm* - Ask user if he wants to proceed further, otherwise exit
- *checkArgs* - Checks if there are sufficient args otherwise executes printHelp
- *put* - Informative output indented line with yellow color
- *warn* - Warning output indented line with red color
- *br* - Display empty line
- *hr* - Display horizontal line
