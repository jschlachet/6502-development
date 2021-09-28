# 6502 Projects

This is a repo of personal projects for 6502 based computers.

## Building

```bash
make
```

## Writing ROM
```bash
make burn ROM=romfilename
```

## Organization
|dir|contents|
|---|--------|
|`config/`|memory map variables, global variables for module|
|`include/`|collections of function based modules|
|`rom/`|generated eeprom images|
|`src/`|main source code|

## Prerequisites

These can be installed via homebrew.

* cc65
* minipro
