# Templates Directory

This directory contains configuration file templates used by the baseline initialization modules.

## Current Templates

Currently, all configuration files are generated inline within the modules for simplicity and maintainability. This directory is reserved for future use if complex template files are needed.

## Usage

If you need to add template files:

1. Place template files here with `.tpl` extension
2. Use variable substitution syntax like `${VARIABLE_NAME}`
3. Reference templates from modules using `${SCRIPT_DIR}/templates/filename.tpl`

## Examples

```bash
# In a module script:
readonly TEMPLATE_FILE="${SCRIPT_DIR}/templates/config.tpl"
envsubst < "$TEMPLATE_FILE" > /etc/myconfig.conf
```