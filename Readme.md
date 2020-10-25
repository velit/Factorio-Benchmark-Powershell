# A Factorio Benchmark Powershell Script

## Features:

* Aggregation of benchmark data into an output CSV file
* Disabling of mods for the duration of the benchmark (can use mods while benchmarking with -enableMods)
* Cpu Priority selection (Cmdline flag -cpuPriority, defaults to "High")
* Various command line options and flags for customizing functionality
* Default values can be changed by editing the script, in the params section
* Regex pattern can be used to pick which saves are benchmarked (-pattern "some pattern")
* By default script loads all savefiles in the given folder.

## Installation

Just download the benchmark.ps1 file and put it somewhere. Or you can copy
paste it and just save it in notepad.

Before running please go through the params section and switch the paths if you
have different ones. The defaults point to steam factorio in default
installation location.

## Usage:

Script will ask ticks and runs:

    .\benchmark.ps1

Giving ticks and runs as a parameter:

    .\benchmark.ps1 6000 10

Giving ticks and runs and selecting the savefile:

    .\benchmark.ps1 6000 10 "Beacon Benchmark"

Also check out the help for all flags, or read the params section of the script

    help benchmark.ps1
