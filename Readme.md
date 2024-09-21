# A Factorio Benchmark Powershell Script

## Features:

* Aggregation of benchmark data into an output CSV file
* Disabling of mods for the duration of the benchmark
    * User mods can be enabled by using -enableMods (Useful for modpack benchmarking)
* Loading of benchmarked savefiles via -savePath
* Regex pattern can be used to further limit which saves are benchmarked via -pattern "some pattern"
* Verbose result mode via -verboseResult allows creation of an excel file where
  separate run results are saved to their own sheets with tick based update
  times
* Cpu Priority selection via -cpuPriority, defaults to "High"

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
path bar and write powershell and press enter. This should open powershell in that folder.

The script has many flags and options to customize its usage. To find out about
all the possible flags please run this in powershell:

    help -detailed .\benchmark.ps1

## Dependencies

Verbose mode depends on [Import-Excel](https://github.com/dfinke/ImportExcel)
to create the output excel file with runs in their own sheets.

Install it by running the following command in powershell:

    Install-Module ImportExcel -scope CurrentUser

## Examples

Script will ask ticks and runs and benchmarks all savefiles found in default save location:

    .\benchmark.ps1

    cmdlet benchmark.ps1 at command pipeline position 1
    Supply values for the following parameters:
    (Type !? for Help.)
    ticks: 6000
    runs: 1

    Following saves found in 'C:\Users\user\AppData\Roaming\Factorio\saves':

    steam_autocloud
    _autosave1
    _autosave2
    Beacon Benchmark
    Belt Benchmark
    Inserter Benchmark
    flame_sla_10k

    Executing benchmark after confirmation. Ctrl-c to cancel. Press Enter to continue...:


Giving ticks, runs and save pattern as parameters:

    .\benchmark.ps1 1000 1 "Benchmark"

    Following saves found matching pattern 'Benchmark':

    Beacon Benchmark
    Belt Benchmark
    Inserter Benchmark

    Executing benchmark after confirmation. Ctrl-c to cancel. Press Enter to continue...:


    Beacon Benchmark Run 1                  0.9445 seconds
    Belt Benchmark Run 1                    2.49479 seconds
    Inserter Benchmark Run 1                5.5595 seconds


Output results can bee seen in Results folder:

    .\Results\flame_sla_10k results.csv:

    Save,Run,Startup time,End time,Avg ms,Min ms,Max ms,Ticks,Execution Time ms,Effective UPS,Version,Platform,Calibration
    flame_sla_10k,1,10.550,14.873,2.892,2.318,25.153,1000,2891.624,345.83,1.1.110,WindowsSteam,
    flame_sla_10k,2,10.483,14.840,2.936,2.358,27.130,1000,2935.500,340.66,1.1.110,WindowsSteam,

Execute using verbose output. This will output an excel file with per-tick data.

    PS> .\benchmark.ps1 1000 2 "flame_sla_10k" -verboseResult

    UNMET DEPENDENCY.

    Export-Excel cmdlet not found for verbose mode.
    Script will continue normally but verbose excel file won't be generated.
    Please install the dependency by running this command in powershell:

        Install-Module ImportExcel -scope CurrentUser

    Ctrl-c to cancel. Press Enter to continue...: <Ctrl-C>

    PS> Install-Module ImportExcel -scope CurrentUser

    Untrusted repository
    You are installing the modules from an untrusted repository. If you trust this repository, change its
    InstallationPolicy value by running the Set-PSRepository cmdlet. Are you sure you want to install the modules from
    'PSGallery'?
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "N"): y

    PS> .\benchmark.ps1 1000 2 "flame_sla" -verboseResult

    Following saves found matching pattern 'flame_sla_10k':

    flame_sla_10k

    Executing benchmark after confirmation. Ctrl-c to cancel. Press Enter to continue...:

    Benchmarking flame_sla_10k Run 1        2.891624 seconds
    Benchmarking flame_sla_10k Run 2        2.9355 seconds

![Verbose Excel Results Example](excel_example.png?raw=true "Verbose Excel Results Example")

The script doesn't generate graphs but this is an example of what's possible by
using per-tick data.

## Contributors

Thanks to KnightElite from the Technical Factorio Discord for the base script!
