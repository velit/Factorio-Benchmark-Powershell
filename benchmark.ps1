# Factorio Benchmark Script v1.1.0
# Depends on Import-Excel https://github.com/dfinke/ImportExcel for -verboseOutput
param (

    ##################
    # BASIC SETTINGS #
    ##################

    # How many ticks to run the benchmark with
    # Script will ask this if not given in the command line
    [Parameter(Mandatory=$true)][int]$ticks,

    # How many repeated runs to run one save with
    # Script will ask this if not given in the command line
    [Parameter(Mandatory=$true)][int]$runs,

    # Saves can be filtered using a pattern to match against the filename
    # Set to "" for no filtering which includes all saves in $savepath
    #
    # Pattern is also by default used as a prefix to the output CSV file
    # See $usePatternAsOutputPrefix
    [string]$pattern = "",

    # Factorio config path
    [string]$configpath = "$env:APPDATA\Factorio\",

    # Saves are loaded recursively from here
    [string]$savepath = "$env:APPDATA\Factorio\saves",

    # Factorio executable path
    [string]$executable = "${env:ProgramFiles(x86)}\Steam\steamapps\common\Factorio\bin\x64\factorio.exe",
    # [string]$executable = "$env:userprofile\Games\Steam\steamapps\common\Factorio\bin\x64\factorio.exe",

    # Logging string that is used in the output CSV file
    [string]$platform = "WindowsSteam",

    # Logging string that signifies some shared property between all the
    # benchmarked save files
    [string]$calibration = "Not given",



    #####################
    # ADVANCED SETTINGS #
    #####################

    # Output csv filename
    [string]$outputName = "results",

    # Output xlsx verbose filename
    [string]$outputNameVerbose = "verbose",

    # Which folder to output results into.
    [string]$outputFolder = ".\Results\",

    # If given, will use $pattern as a prefix to the output file
    [switch]$usePatternAsOutputPrefix = $true,

    # If given preserve the raw logs produced by factorio.exe
    [switch]$keepLogs = $false,

    # If given and $output file exists clear it before running
    [switch]$clearOutputFile = $false,

    # If given disables automatic mod disabling feature
    [switch]$enableMods = $false,

    # If given enables verbose mode which logs per-tick benchmarks
    [switch]$verboseResult = $false,

    # Which items are selected for verbose logging
    #
    # Available options are:
    #
    # tick,timestamp,wholeUpdate,latencyUpdate,gameUpdate,circuitNetworkUpdate,transportLinesUpdate,fluidsUpdate,heatManagerUpdate,entityUpdate,particleUpdate,mapGenerator,mapGeneratorBasicTilesSupportCompute,mapGeneratorBasicTilesSupportApply,mapGeneratorCorrectedTilesPrepare,mapGeneratorCorrectedTilesCompute,mapGeneratorCorrectedTilesApply,mapGeneratorVariations,mapGeneratorEntitiesPrepare,mapGeneratorEntitiesCompute,mapGeneratorEntitiesApply,crcComputation,electricNetworkUpdate,logisticManagerUpdate,constructionManagerUpdate,pathFinder,trains,trainPathFinder,commander,chartRefresh,luaGarbageIncremental,chartUpdate,scriptUpdate,
    #
    # tick must be one of the selected items, otherwise the script won't work
    [string]$verboseItems = "tick,wholeUpdate,wholeUpdate,gameUpdate,circuitNetworkUpdate,transportLinesUpdate,fluidsUpdate,entityUpdate,electricNetworkUpdate,logisticManagerUpdate,trains,trainPathFinder",

    # Can customize used CPU priority.
    [string]$cpuPriority = "High",

    # Can customize CPU affinity.
    # Sum the numbers associated with the cores to get the cores you want
    # factorio to run in.
    # #1 = 1, #2 = 2, #3 = 4, #4 = 8, #5 = 16, #6 = 32, #7 = 64, #8 = 128
    # Eg. enabling core 1, 3 and 5 is 1 + 4 + 16 = 21
    # 0 to disable feature
    [int]$cpuAffinity = 0
)
#End of user variables

$ErrorActionPreference = "Stop"

$excelEnabled = $false
if (Get-Command Export-Excel -errorAction SilentlyContinue)
{
  $excelEnabled = $true
}
elseif ($verboseResult) {
  Write-Output "`nUNMET DEPENDENCY. Export-Excel cmdlet not found for verbose mode." `
    "Please install it by running this command in powershell:" `
    "`n    Install-Module ImportExcel -scope CurrentUser`n" `
    "Script will run normally but verbose excel file won't be generated."
}

# Collect the saves to benchmark
Write-Output ""
if ($pattern -ne "") {
  [array]$saves = dir $savepath -file -recurse | where {$_.BaseName -Match $pattern}
  $saveFoundMessage = "found matching pattern '$pattern'"
}
else {
  [array]$saves = dir $savepath -file -recurse
  $saveFoundMessage = "found in '$savepath'"
}

if ($saves.length -ne 0) {
  Write-Output "Following saves ${saveFoundMessage}:"
}
else {
  Write-Output "No saves $saveFoundMessage."
  Write-Output ""
  exit
}

Write-Output ""
Write-Output $($saves | select -ExpandProperty BaseName)
Write-Output ""
Write-Host -NoNewline "Executing benchmark after confirmation. Ctrl-c to cancel. "
pause

try {

  $sanitized_pattern = ""
  if ($usePatternAsOutputPrefix) {
    # Remove illegal filename characters from pattern for output filename
    $sanitized_pattern = ($pattern.Split([IO.Path]::GetInvalidFileNameChars()) -join '_') + " "
  }
  [System.IO.FileInfo]$output = Join-Path $outputFolder -ChildPath ($sanitized_pattern + $outputName + ".csv")
  [System.IO.FileInfo]$outputVerbose = Join-Path $outputFolder -ChildPath ($sanitized_pattern + $outputNameVerbose + ".xlsx")

  # Delete output file if feature is enabled
  if ($clearOutputFile) {
    if (Test-Path $output) {
      rm $output
    }
    if (Test-Path $outputVerbose) {
      rm $outputVerbose
    }
  }

  # Check if output file already exists
  if (-not (Test-Path $output)) {
    # Create folders for output file
    [Void](New-Item -Force (Split-Path -Path $output) -ItemType Directory)

    # Create output and print headers
    Write-Output "Save,Run,Startup time,End time,Avg ms,Min ms,Max ms,Ticks,Execution Time ms,Effective UPS,Version,Platform,Calibration" > $output
  }

  # Mod disabling block
  if (-not $enableMods) {
    $modsPath = Join-Path -Path $configpath -ChildPath "mods"
    $backupPath = Join-Path -Path $configpath -ChildPath "mods_disabled"
    if (Test-Path $modsPath) {
      if (-not (Test-Path $backupPath)) {
        Write-Output "Disabling mods."
        Move-Item -Path $modsPath -Destination $backupPath
      }
      else {
        Write-Output "Mods already disabled previously. Doing nothing."
      }
    }
    else {
      Write-Output "Mod folder not found. Doing nothing."
    }
  }

  Write-Output ""
  # Main benchmark loop
  for ($i = 0; $i -lt $runs; $i++) {
    for ($j = 0; $j -lt $saves.length; $j++) {
      $run = $i + 1
      $save = $saves[$j].FullName
      $saveName = $saves[$j].BaseName
      $runName = $saveName + " Run " + $run
      $logPath = Join-Path $outputFolder ($runName + ".log")

      Write-Host -NoNewline "Benchmarking $runName`t"

      # Run factorio
      $argList = "--benchmark `"$save`" --benchmark-ticks $ticks --disable-audio"
      
      if ($verboseResult) {
        $argList += " --benchmark-verbose " + $verboseItems
      }

      $process = Start-Process -PassThru -FilePath $executable -ArgumentList $argList -RedirectStandardOutput $logPath

      # Set process flags and wait for execution to finish
      $process.PriorityClass = $cpuPriority
      if ($cpuAffinity -ne 0) {
        $process.ProcessorAffinity = $cpuAffinity
      }
      $process.WaitForExit()

      # Perform a cleanup pass on the data, since depending on the time to benchmark a number of spaces will be added to
      # the lines
      $logData = (Get-Content $logPath) -replace '^\s+', ''
      $logData | Set-Content $logPath

      # Parse data
      $avg = (($logData | Select-String "avg:") -split " ")[1]
      $min = (($logData | Select-String "avg:") -split " ")[4]
      $max = (($logData | Select-String "avg:") -split " ")[7]
      $version = (($logData | Select-Object -First 1) -split " ")[4]
      $executionTime = (($logData | Select-String "Performed") -split " ")[4]
      $startupTime = (($logData | Select-String "Loading script.dat") -split " ")[0]
      $endTime = (($logData | Select-Object -Last 1) -split " ")[0]
      $effectiveUPS  = [math]::Round((1000 * $ticks / $executionTime), 2)

      # Save the results
      Write-Output "$($executionTime / 1000) seconds"
      Write-Output "$saveName,$run,$startupTime,$endTime,$avg,$min,$max,$ticks,$executionTime,$effectiveUPS,$version,$platform,$calibration" >> $output

      # If verbose result is enabled produce a separarte excel file with verbose results
      if (($verboseResult) -and ($excelEnabled)) {
        $time = Get-Date -Format "HHmm "

        # Select run-specific lines
        # remove 't' from tick number
        $verboseData = $logData `
          | Select-String -Pattern "(^tick,)|(^t\d+)," `
          | ForEach-Object {$_ -Replace "^t(\d+)", '$1'} `
          | ConvertFrom-Csv `

        # Change to milliseconds and make ticks 1-based
        $verboseData | ForEach-Object { 
          foreach ($property in $_.PSObject.Properties) {
            if ($property.Name -eq "tick") {
              [int]$property.Value += 1
            }
            else {
              $property.Value = $property.Value / 1000000
            }
          }
        }

        # Output excel file
        $verboseData | Export-Excel -AutoSize -WorksheetName ($time + $runName) $outputVerbose
      }

      if (-not ($keepLogs)) {
        rm "$logPath"
      }
    }
  }
}
# Cleanup
finally {
  if (-not $enableMods) {
    if (Test-Path $backupPath) {
      if (Test-Path $modsPath) {
        Write-Output "`nRestoring original mods."
        mv -Force (Join-Path -Path $backupPath -ChildPath "\*") $modsPath
        rm $backupPath
      }
      else {
        Write-Output "Mods folder not created. Probably factorio didn't run. Restoring mods."
        mv $backupPath $modsPath
      }
    }
  }
}
