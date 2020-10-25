param (
    [Parameter(Mandatory=$true)][int]$ticks = 0,
    [Parameter(Mandatory=$true)][int]$runs = 0,

    # Saves can be filtered using a pattern to match against the filename
    # Set to "" for no filtering which includes all saves in $savepath
    [string]$pattern = "",

    # Path of the results file
    [string]$output = ".\results.csv",

    # If given preserve the raw logs produced by factorio.exe
    [switch]$keepLogs = $false,

    # If given and $output file exists clear it before running
    [switch]$clearOutputFile = $false,

    # If given will allow using mods
    [switch]$enableMods = $false,

    # If given, don't interleave runs and use factorio.exe run mechanism which is faster in real time
    # TODO: implement
    # [switch]$noRunInterleaving = $false,

    # Factorio config path
    [string]$configpath = "$env:APPDATA\Factorio\",

    # Saves are loaded recursively from here
    [string]$savepath = "$env:APPDATA\Factorio\saves",

    # Saves are loaded recursively from here
    [string]$cpuPriority = "High",

    # Sum the numbers associated with the cores to get the cores you want
    # factorio to run in.
    # #1 = 1, #2 = 2, #3 = 4, #4 = 8, #5 = 16, #6 = 32, #7 = 64, #8 = 128
    # Eg. enabling core 1, 3 and 5 is 1 + 4 + 16 = 21
    # 0 to disable feature
    [int]$cpuAffinity = 0,

    # Factorio executable path
    [string]$executable = "${env:ProgramFiles(x86)}\Steam\steamapps\common\Factorio\bin\x64\factorio.exe",
    # [string]$executable = "$env:userprofile\Games\Steam\steamapps\common\Factorio\bin\x64\factorio.exe",

    # Logging string that is used in the output CSV file
    [string]$platform = "WindowsSteam"
)
#End of user variables



$ErrorActionPreference = "Stop"

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

  if (($clearOutputFile) -and (Test-Path $output)) {
    rm $output
  }

  if (-not (Test-Path $output)) {
    echo "save_name,run,startup_time_s,end_time_s,avg_ms,min_ms,max_ms,ticks,execution_time_ms,effective_UPS,version,platform" > $output
  }

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


  # Runs are indexed such that they are interleaved when testing, so no save has any substantial advantage to going first or last
  for ($i = 0; $i -lt $runs; $i++) {
    for ($j = 0; $j -lt $saves.length; $j++) {
      $run = $i + 1
      $save = $saves[$j].FullName
      $save_name = $saves[$j].BaseName
      $log_filename = $save_name + " Run" + $run + ".log"

      Write-Host -NoNewline "Benchmarking '$log_filename' "
      $arg_list = "--benchmark `"$save`" --benchmark-ticks $ticks --disable-audio"
      $process = Start-Process -PassThru -FilePath "$executable" -ArgumentList $arg_list -RedirectStandardOutput "$log_filename"
      $process.PriorityClass = $cpuPriority
      if ($cpuAffinity -ne 0) {
        $process.ProcessorAffinity = $cpuAffinity
      }
      $process.WaitForExit()

      # Perform a cleanup pass on the data, since depending on the time to benchmark a number of spaces will be added to the lines
      $log_data = (Get-Content $log_filename) -replace '^\s+', ''
      $log_data | Set-Content $log_filename

      $avg_ms = (($log_data | Select-String "avg:") -split " ")[1]
      $min_ms = (($log_data | Select-String "avg:") -split " ")[4]
      $max_ms = (($log_data | Select-String "avg:") -split " ")[7]
      $version = (($log_data | Select-Object -First 1) -split " ")[4]
      $execution_time_ms = (($log_data | Select-String "Performed") -split " ")[4]
      $startup_time_s = (($log_data | Select-String "Loading script.dat") -split " ")[0]
      $end_time_s = (($log_data | Select-Object -Last 1) -split " ")[0]
      $effective_UPS  = [math]::Round((1000 * $ticks / $execution_time_ms), 2)
      echo "$save_name,$run,$startup_time_s,$end_time_s,$avg_ms,$min_ms,$max_ms,$ticks,$execution_time_ms,$effective_UPS,$version,$platform" >> $output
      echo "end_time $end_time_s seconds"

      if (-not ($keepLogs)) {
        rm "$log_filename"
      }
    }
  }
}
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
