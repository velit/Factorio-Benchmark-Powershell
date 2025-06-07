# A Factorio Benchmark Powershell Script

#### Regular results

![Regular Results Example](results_example.png?raw=true "Regular Results Example")

#### -verboseOutput results

![Verbose Results Example](verbose_example.png?raw=true "Verbose Results Example")

The script doesn't automatically generate graphs but this is an example of
what's possible with per-tick data generated with -verboseOutput

## Features:

* Aggregation of benchmark data into output files
* Disabling of mods for the duration of the benchmark
    * User mods can be enabled by using -enableMods (Useful for modpack benchmarking)
* Loading of benchmarked savefiles via -savePath
* Regex pattern can be used to further limit which saves are benchmarked via -pattern "some pattern"
* Verbose result mode via -verboseResult allows creation of an xlsx file where
  separate run results are saved to their own sheets with tick based update times
* Cpu Priority selection via -cpuPriority, defaults to "High"

Various other command line options and flags for customizing functionality per invocation.
Default values can be changed by editing the script, in the params section

## Installation

Download the ```benchmark.ps1``` file and put it somewhere. Or you can copy
paste it and just save it in notepad.

If you are not using the steam version of factorio in its default path open the
script in notepad and change the following line in the basic settings section
to point to the factorio executable:

    [string]$executable = "${env:ProgramFiles(x86)}\Steam\steamapps\common\Factorio\bin\x64\factorio.exe",

Don't worry about the ```${env:ProgramFiles(x86)}``` bit that's only there to make it
work out of the box for most people.

If your factorio executable is in ```C:\Games\Factorio\bin\x64\factorio.exe```
then change the line to the following:

    [string]$executable = "C:\Games\Factorio\bin\x64\factorio.exe",

The script has many similar options that you can either use command line
arguments to change or you can change the default values directly in the
script.

## Usage:

Open the folder you put the ```benchmark.ps1``` script in using explorer. Select the
path bar and write powershell and press enter. This should open powershell in that folder.

The script has many flags and options to customize its usage. To find out about
all the possible flags please run this in powershell:

    help -detailed .\benchmark.ps1

## Dependencies

Better output files depend on
[Import-Excel](https://github.com/dfinke/ImportExcel) to create output .xlsx
files.

Verbose output is possible with per-tick runs all in their own sheets.

Regular output file handles better localization and easier import to
spreadsheet software (doesn't have to be excel).

Install it by running the following command in powershell:

    Install-Module ImportExcel -scope CurrentUser

## Examples

#### Script will ask ticks and runs and benchmarks all savefiles found in default save location:

    .\benchmark.ps1

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


#### Giving ticks, runs and save pattern as parameters:

    .\benchmark.ps1 1000 1 "Benchmark"

    Following saves found matching pattern 'Benchmark':

    Beacon Benchmark
    Belt Benchmark
    Inserter Benchmark

    Executing benchmark after confirmation. Ctrl-c to cancel. Press Enter to continue...:


    Beacon Benchmark Run 1                  0.9445 seconds
    Belt Benchmark Run 1                    2.49479 seconds
    Inserter Benchmark Run 1                5.5595 seconds


Output results can bee seen in `Results\Results.csv`:

    Save,Run,Startup time,End time,Avg ms,Min ms,Max ms,Ticks,Execution Time ms,Effective UPS,Version,Platform,Calibration
    flame_sla_10k,1,10.550,14.873,2.892,2.318,25.153,1000,2891.624,345.83,1.1.110,WindowsSteam,
    flame_sla_10k,2,10.483,14.840,2.936,2.358,27.130,1000,2935.500,340.66,1.1.110,WindowsSteam,

#### Execute using verbose output. This will output an xlsx file with per-tick data.

    PS> .\benchmark.ps1 1000 2 "flame_sla_10k" -verboseResult

    UNMET DEPENDENCY.

    Export-Excel cmdlet not found for verbose mode.
    Script will continue normally but verbose results file won't be generated.
    Please install the dependency by running this command in powershell:

        Install-Module ImportExcel -scope CurrentUser

    Ctrl-c to cancel. Press Enter to continue...:

If the ImportExcel dependency is not installed you will get this message.

Ctrl-c out of it and install the dependency:

    PS> Install-Module ImportExcel -scope CurrentUser

    Untrusted repository
    You are installing the modules from an untrusted repository. If you trust this repository, change its
    InstallationPolicy value by running the Set-PSRepository cmdlet. Are you sure you want to install the modules from
    'PSGallery'?
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "N"): y

Then you're free to retry the command:

    PS> .\benchmark.ps1 1000 2 "flame_sla" -verboseResult

    Following saves found matching pattern 'flame_sla_10k':

    flame_sla_10k

    Executing benchmark after confirmation. Ctrl-c to cancel. Press Enter to continue...:

    Benchmarking flame_sla_10k Run 1        2.891624 seconds
    Benchmarking flame_sla_10k Run 2        2.9355 seconds

Verbose results can be found in `.\Results\Verbose Results.xlsx`:

## Full Parameter List

### -ticks Int32

Specify the amount of ticks of simulation for each benchmark savefile run

### -runs Int32

Specify the amount of times to repeat each benchmark savefile

### -pattern String

Benchmark filenames can be filtered using this pattern
Defaults to all savefiles found in ### -savepath

This setting is by default also used as a prefix to the result files
See -removePatternAsOutputPrefix

### -configpath String

Factorio config path
Defaults to $env:APPDATA\Factorio\ (Default Factorio config folder)

### -savepath String

Factorio save path
Savefiles are collected recursively from this path
Defaults to $env:APPDATA\Factorio\saves (Default Factorio save folder)

### -executable String

Factorio executable path
Defaults to ${env:ProgramFiles(x86)}\Steam\steamapps\common\Factorio\bin\x64\factorio.exe (Default Steam installation folder)

### -platform String

Logging string that is used in the regular output file
Defaults to WindowsSteam
This is just for convention/convenience and is not used in any logic

### -notes String

Logging string that is used in the regular output file
Add whatever notes you would like to be included for the given runs
This is just for convention/convenience and is not used in any logic

### -outputName String

Base output filename (csv/xlsx)
Default is results

### -outputNameVerbose String

Base verbose output filename (always xlsx)
Default is verbose

### -outputFolder String

Output results folder

### -forceCSV

Script will default to using xlsx output if Export-Excel dependency is
installed. You may force the non-verbose output file to always be CSV with
this if you so wish.

Note: Usage of Excel specifically is not mandatory even with .xlsx files.
Spreadsheet software just tend to import the data better in more rigid
file formats than .csv which has issues with localization for example with
decimal separators.

### -usePatternAsOutputPrefix

Add -pattern string to output files as prefix.
Useful if you don't want all your results ending up in the same files.

### -keepLogs

If given preserve the raw logs produced by factorio.exe

### -clearOutputFile

If given and -output file exists clear it before running

### -enableMods

If given use user's normal mods
By default a separate mod folder is used
This separate mod folder can be specified with -benchmarkModFolder

### -benchmarkModFolder String

If -enableMods isn't given use this folder as the target for benchmarking mods
Defaults to ./benchmark-mods/
Note factorio expects this path in unix format with forward slashes for separators

### -verboseResult

If given enables verbose mode which logs per-tick benchmarks and outputs
an xlsx file

### -verboseItems String

Specify the list of items included in verbose -verboseResult output. Valid items are:

    tick,timestamp,wholeUpdate,latencyUpdate,gameUpdate,circuitNetworkUpdate,transportLinesUpdate,fluidsUpdate,heatManagerUpdate,entityUpdate,particleUpdate,mapGenerator,mapGeneratorBasicTilesSupportCompute,mapGeneratorBasicTilesSupportApply,mapGeneratorCorrectedTilesPrepare,mapGeneratorCorrectedTilesCompute,mapGeneratorCorrectedTilesApply,mapGeneratorVariations,mapGeneratorEntitiesPrepare,mapGeneratorEntitiesCompute,mapGeneratorEntitiesApply,crcComputation,electricNetworkUpdate,logisticManagerUpdate,constructionManagerUpdate,pathFinder,trains,trainPathFinder,commander,chartRefresh,luaGarbageIncremental,chartUpdate,scriptUpdate,

tick must be one of the selected items, otherwise the script won't work

### -cpuPriority String

Specify which CPU priority to use. Valid values are:

Idle, BelowNormal, Normal, AboveNormal, High, or RealTime

Defaults to High

### -cpuAffinity Int32

Specify CPU affinity. Valid values between 0 - 255

Sum the numbers associated with the cores to specify the cores you want factorio to run in.

* Core 1 = 1
* Core 2 = 2
* Core 3 = 4
* Core 4 = 8
* Core 5 = 16
* Core 6 = 32
* Core 7 = 64
* Core 8 = 128

Eg. enabling core 1, 3 and 5 is 1 + 4 + 16 = 21

Defaults to 0 which disables affinity specification altogether

## Contributors

Thanks to KnightElite from the Technical Factorio Discord for the base script!
