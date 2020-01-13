
param (
    [string]$TVAfile = "$($(Get-Location).path)\TVA.xml"   
)




#region HISTORY.TXT
<#

  Version - Date DD/MM/YYYY - Remarks
  
  v0.1  - NA/NA/2018
  v0.3  - Added HTTP METHOD testing method, no download of file is required.
  v0.4  - Added several choices/output options, etc...
  v0.41 - bugfix on NoDownload cmdline switch. Moved all to choices.
 
#>
#endregion



$infile=$TVAFile

#bit of nastyness to fix $file starting with a '.'
 [regex] $pattern='^\.' # starts with a .
 $file=$pattern.Replace($file, $pwd.path,1) #test the pattern against $file, replace the 1st occurence


Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG","JUSTINDENT","FLAG")]
    [String]
    $Level = "INFO",

    [Parameter(Mandatory=$True,ValueFromPipeline=$True)]    
    [string]
    $Message,

    [Parameter(Mandatory=$False)]
    [string]
    $logfile,

    [Parameter(Mandatory=$False)]
    [string]
    $OnScreen = $False
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    if ($Level -eq 'JUSTINDENT') 
       {
        $Line = "                         $Message"
       }
       else 
           { 
            $Line = "$Stamp $Level $Message"
        }
    If($logfile) {
        Add-Content $logfile -Value $Line
        if ($OnScreen -eq $true ) {Write-Output $Line}
    }
    Else {
        Write-Output $Line
    }
}


filter Get-FileSize {

	"{0:N2} {1}" -f $(

	if ($_ -lt 1kb) { $_, 'Bytes' }

	elseif ($_ -lt 1mb) { ($_/1kb), 'KB' }

	elseif ($_ -lt 1gb) { ($_/1mb), 'MB' }

	elseif ($_ -lt 1tb) { ($_/1gb), 'GB' }

	elseif ($_ -lt 1pb) { ($_/1tb), 'TB' }

	else { ($_/1pb), 'PB' }

	)

}

function Get-FileInvokeWebRequest{

    param(

        [Parameter(Mandatory=$true)]

        $url, 

        $destinationFolder="$env:USERPROFILE\Downloads", 

        [switch]$includeStats,
        [switch]$DoNotDownload


    )


    if ($DoNotDownload.IsPresent) # fetch the file from the server
       {
         $start = Get-Date
         $tmp=Invoke-WebRequest $url -Method HEAD
         $elapsed = ((Get-Date) - $start).ToString('hh\:mm\:ss')
            if ($includeStats.IsPresent)
              {
                Write-Log -Level INFO -logfile $logfile -Message "Totalsize: $($tmp.BaseResponse.ContentLength) Duration: $elapsed"
              }

    }
     else # just use the HEAD method, no donwload required.
        {

        $destination = Join-Path $destinationFolder ($url | Split-Path -Leaf)
        $start = Get-Date
        Invoke-WebRequest $url -OutFile $destination
        $elapsed = ((Get-Date) - $start).ToString('hh\:mm\:ss')
        $totalSize = (Get-Item $destination).Length | Get-FileSize
        if ($includeStats.IsPresent){
            #[PSCustomObject]@{Name=$MyInvocation.MyCommand;TotalSize=$totalSize;Time=$elapsed}
            Write-Log -Level INFO -logfile $logfile -Message "Totalsize: $totalSize Duration of Download: $elapsed"
        }
        Get-Item $destination | Unblock-File
        }

}



clear

$RunPath = Get-Location
$temppath="$RunPath\$(Get-Date -Format "yyyyMMdd-hhmmss")"

$hash_failedURI=@{}

$Username = "" 
$Password = "" 
$Path = Get-Location 
$WebClient = New-Object System.Net.WebClient 
$WebClient.Credentials = New-Object System.Net.Networkcredential($Username, $Password) 
$pattern ='(?i)(?<=<mpeg7:MediaUri>)(http.*g)(?=</mpeg7:MediaUri>)'
$timestamp=Get-Date -Format "ddMMyyyy-HHMMss"
$scriptver="0.41"

if ( (Test-Path $infile -ErrorAction Stop) -eq $false ) 
  { # there's an invalid file 
  Write-Log -Level ERROR -Message "$($infile) not found!"
  Write-Log -Level INFO -Message "Usage:: Either have TVA.xml in the same folder or run script with: 'testPoster.ps1 <full path to your tva file, eg.: X:\path\yourfile.xml>'"
  break
  }
  else 
      {
       Write-Log -Level INFO  -Message "Using: $infile ..."       
       $logfile="$(Split-path -Path $infile)\$([System.IO.Path]::GetFileNameWithoutExtension($infile)).$($timestamp).log"       
       Write-Log -Level INFO -logfile $logfile  -Message "Opening Log-file: $logfile"
      }
Write-Log -Level INFO -logfile $logfile -Message "/***************************************\*"
Write-Log -Level INFO -logfile $logfile -Message "|* Quick PosterServer Tester / RTi $scriptver *|"
Write-Log -Level INFO -logfile $logfile -Message "\***************************************/*"
Write-Log -Message "It is now: $(get-date), Timezone is $($(Get-TimeZone).Id)"

write-Log -Level INFO -logfile $logfile -Message "Grabbing & de-duping Image URIs from $($infile)..."

 $tmparr=(select-string -path $infile -allmatches -pattern $pattern).Matches.Value
    $ht = @{}
    $tmparr | foreach { $ht["$_"] += 1 }

$total=0
$ht.Values | foreach {$total=$total+$_}


write-log -Level INFO -logfile $logfile -Message "Found $($total) total URIs => $($ht.keys.Count) Unique URIs to test..."

Write-Log -Level INFO -logfile $logfile -Message "Running out of $($Path), Logging to $($logfile) ..."

do {
  $x=(Read-Host "Select ""U"" to write out list of URIs, F to write out list of filenames, T to test found URIs, D to download or X to exit without testing [U/F/T/D/X]").ToUpper()
} until (($x -match "[DFTUX]"))

$Download = ($x -match 'D')

switch -Regex ($x)
{
  '[U]' {
       write-log -Level INFO -logfile $logfile -Message "Writing URIs to $($infile).URI.TXT"
       $ht.Keys | out-file -Encoding utf8 -FilePath "$($infile).uri.txt"
       write-log -Level INFO -logfile $logfile -Message "Exit!"
       break

      }
  '[F]' {
       write-log -Level INFO -logfile $logfile -Message "Writing filenames to $($infile).files.TXT"
       $ht.Keys | foreach { [System.IO.Path]::GetFileName($_) } | out-file -Encoding utf8 -FilePath "$($infile).files.txt" -Append
       write-log -Level INFO -logfile $logfile -Message "Exit!"
       break
      }
  '[DT]' {

        If ($Download -eq $true) 
          {
            Write-Log -Level INFO -logfile $logfile -Message "Download Mode enabled => Creating temporary download directory $($temppath)..."
          }
         else 
             { 
              Write-Log -Level INFO -logfile $logfile -Message "Download Mode disabled; using HTTP/HEAD to check images..."
             }

        $result= New-item -ItemType Directory $temppath -Force
        Write-Log -Level INFO -logfile $logfile -Message "------------------------------------"
        $counter=0
        #start fetching the stuff...
        foreach ($url in $ht.Keys) {
                $counter +=1
                $msg="Processing Item ($($counter)/$(($ht.Keys).count)) : $url..."        
                Write-Progress -id 1 -PercentComplete ($counter / (($ht.Keys).count) * 100 ) -Activity $msg
            if ($Download -eq $true) 
               { 
                 Write-log -level INFO -logfile $logfile -Message "Attempting to Download $url to $temppath ..."
               }
              else {
                     Write-log -level INFO -logfile $logfile -Message "Attempting to Fetch $url..."
                   }
            Write-log -level INFO -logfile $logfile -Message "# of references in processed file: $($ht[$url])"
            try
            {
             if ($Download -eq $false) 
                { 
                 Get-FileInvokeWebRequest -url $url -destinationFolder "$temppath" -includeStats -DoNotDownload
                }
                else { Get-FileInvokeWebRequest -url $url -destinationFolder "$temppath" -includeStats}
            }
            catch [System.Net.WebException]{      
              Write-Log -Level ERROR -logfile $logfile -Message "Caught Exception $($_.Exception.Message): Unable to download $url"
              $hash_failedURI.Add("$url","1")
             }    
        }

        Write-Log -Level INFO -logfile $logfile -Message "------------------------------------"
        If ($hash_failedURI.keys.Count -gt 0) 
          {   
           Write-Log -Level INFO -logfile $logfile -Message "Failed URIs:"
           Write-Log -Level INFO -logfile $logfile -Message "-------------"
            foreach ($uri in $hash_failedURI.keys) 
                    {
                     Write-Log -Level ERROR -logfile $logfile -Message "Failed URI: $uri"
                    }

           } 
           else 
                {
                 Write-Log -Level INFO -logfile $logfile -OnScreen $true -Message "NO Failed URIs - All good :)!"
                }


        #now, need to purge the temp folder...
        If ($Download -eq $true) 
          {
            Write-Log -level INFO -logfile $logfile -Message "Purging temporary download directory: $($temppath)"
            $result= Remove-Item $temppath -Force -Recurse
          }
       write-log -Level INFO -logfile $logfile -Message "Exit!"
       break


      }
  '[X] ' {
       write-log -Level INFO -logfile $logfile -Message "Exit!"
       break
      }

}


