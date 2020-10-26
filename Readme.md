# A Factorio Benchmark Powershell Script

## Features:

* Aggregation of benchmark data into an output CSV file
* Disabling of mods for the duration of the benchmark (can use mods while benchmarking with -enableMods)
* Cpu Priority selection (Cmdline flag -cpuPriority, defaults to "High")
* Loading of benchmarked savefiles via a command line param / config param (-savePath / $savePath)
* Regex pattern can be used to further limit which saves are benchmarked (-pattern "some pattern")

Various other command line options and flags for customizing functionality.
Default values can be changed by editing the script, in the params section

## Installation

Download the ```benchmark.ps1``` file and put it somewhere. Or you can copy
paste it and just save it in notepad.

Before running please go through at least the Basic Settings section of the
script and switch the paths that are different for you. The defaults use Steam
Factorio paths.

## Usage:

Open the folder you put the ```benchmark.ps1``` script in using explorer. Select the
path bar and write powershell. This should open powershell in that folder.

Script will ask ticks and runs:

    .\benchmark.ps1

Giving ticks and runs as a parameter:

    .\benchmark.ps1 6000 10

Giving ticks and runs and selecting the savefile:

    .\benchmark.ps1 6000 10 "Beacon Benchmark"

Also check out the help for all flags, or read the params section of the script

    help benchmark.ps1
