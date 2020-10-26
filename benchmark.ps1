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



    #####################
    # ADVANCED SETTINGS #
    #####################

    # Output filename
    [string]$outputName = "results.csv",

    # Which folder to output results into.
    [string]$outputFolder = ".\data\",

    # If given, will use $pattern as a prefix to the output file
    [switch]$usePatternAsOutputPrefix = $true,

    # If given preserve the raw logs produced by factorio.exe
    [switch]$keepLogs = $false,

    # If given and $output file exists clear it before running
    [switch]$clearOutputFile = $false,

    # If given disables automatic mod disabling feature
    [switch]$enableMods = $false,

    # Can customize used CPU priority.
    [string]$cpuPriority = "High",

    # Can customize CPU affinity.
    # Sum the numbers associated with the cores to get the cores you want
    # factorio to run in.
    # #1 = 1, #2 = 2, #3 = 4, #4 = 8, #5 = 16, #6 = 32, #7 = 64, #8 = 128
    # Eg. enabling core 1, 3 and 5 is 1 + 4 + 16 = 21
    # 0 to disable feature
    [int]$cpuAffinity = 0

    # If given, don't interleave runs and use factorio.exe run mechanism which is faster in real time
    # TODO: implement
    # [switch]$noRunInterleaving = $false,
)
#End of user variables

$ErrorActionPreference = "Stop"

# Collect the saves to benchmark
echo ""
if ($pattern -ne "") {
  [array]$saves = dir $savepath -file -recurse | where {$_.BaseName -Match $pattern}
  echo "Following saves matched pattern '$pattern':"
}
else {
  [array]$saves = dir $savepath -file -recurse
  echo "All saves in '$savepath':"
}

if ($saves.length -eq 0) {
  echo "No saves were found that matched pattern '$pattern'"
  exit
}

echo ""
echo $($saves | select -ExpandProperty BaseName)
echo ""
Write-Host -NoNewline "Executing benchmark after confirmation. Ctrl-c to cancel. "
pause

try {

  $sanitized_pattern = ""
  if ($usePatternAsOutputPrefix) {
    # Remove illegal filename characters from pattern for output filename
    $sanitized_pattern = ($pattern.Split([IO.Path]::GetInvalidFileNameChars()) -join '_') + " "
  }
  [System.IO.FileInfo]$output = Join-Path $outputFolder -ChildPath ($sanitized_pattern + $outputName)

  # Delete output file if feature is enabled
  if (($clearOutputFile) -and (Test-Path $output)) {
    rm $output
  }

  # Check if output file already exists
  if (-not (Test-Path $output)) {
    # Create folders for output file
    New-Item -Force (Split-Path -Path $output) -ItemType Directory

    # Create output and print headers
    echo "save_name,run,startup_time_s,end_time_s,avg_ms,min_ms,max_ms,ticks,execution_time_ms,effective_UPS,version,platform" > $output
  }

  # Mod disabling block
  if (-not $enableMods) {
    $mods_path = Join-Path -Path $configpath -ChildPath "mods"
    $backup_path = Join-Path -Path $configpath -ChildPath "mods_disabled"
    if (Test-Path $mods_path) {
      if (-not (Test-Path $backup_path)) {
        echo "Disabling mods."
        Move-Item -Path $mods_path -Destination $backup_path
      }
      else {
        echo "Mods already disabled previously. Doing nothing."
      }
    }
    else {
      echo "Mod folder not found. Doing nothing."
    }
  }

  echo ""
  # Main benchmark loop
  for ($i = 0; $i -lt $runs; $i++) {
    for ($j = 0; $j -lt $saves.length; $j++) {
      $run = $i + 1
      $save = $saves[$j].FullName
      $save_name = $saves[$j].BaseName
      $log_path = Join-Path $outputFolder ($save_name + " Run" + $run + ".log")

      Write-Host -NoNewline "Benchmarking '$save_name' Run $run`t"

      # Run factorio
      $arg_list = "--benchmark `"$save`" --benchmark-ticks $ticks --disable-audio"
      $process = Start-Process -PassThru -FilePath $executable -ArgumentList $arg_list -RedirectStandardOutput $log_path

      # Set process flags and wait for execution to finish
      $process.PriorityClass = $cpuPriority
      if ($cpuAffinity -ne 0) {
        $process.ProcessorAffinity = $cpuAffinity
      }
      $process.WaitForExit()

      # Perform a cleanup pass on the data, since depending on the time to benchmark a number of spaces will be added to the lines
      $log_data = (Get-Content $log_path) -replace '^\s+', ''
      $log_data | Set-Content $log_path

      # Parse data
      $avg_ms = (($log_data | Select-String "avg:") -split " ")[1]
      $min_ms = (($log_data | Select-String "avg:") -split " ")[4]
      $max_ms = (($log_data | Select-String "avg:") -split " ")[7]
      $version = (($log_data | Select-Object -First 1) -split " ")[4]
      $execution_time_ms = (($log_data | Select-String "Performed") -split " ")[4]
      $startup_time_s = (($log_data | Select-String "Loading script.dat") -split " ")[0]
      $end_time_s = (($log_data | Select-Object -Last 1) -split " ")[0]
      $effective_UPS  = [math]::Round((1000 * $ticks / $execution_time_ms), 2)

      # Save the results
      echo "$save_name,$run,$startup_time_s,$end_time_s,$avg_ms,$min_ms,$max_ms,$ticks,$execution_time_ms,$effective_UPS,$version,$platform" >> $output

      echo "end_time $end_time_s seconds"

      if (-not ($keepLogs)) {
        rm "$log_path"
      }
    }
  }
}
# Cleanup
finally {
  if (-not $enableMods) {
    if (Test-Path $backup_path) {
      if (Test-Path $mods_path) {
        echo "`nRestoring original mods."
        mv -Force (Join-Path -Path $backup_path -ChildPath "\*") $mods_path
        rm $backup_path
      }
      else {
        echo "Mods folder not created. Probably factorio didn't run. Restoring mods."
        mv $backup_path $mods_path
      }
    }
  }
}
