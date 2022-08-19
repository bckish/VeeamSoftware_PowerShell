$shareFolder = "C:\Users\kishb\OneDrive\Desktop\Power shell\source_file"
$localFolder = "C:\Users\kishb\OneDrive\Desktop\Power shell\traget_file"

function syncDir {

    param([string]$Folder1, [string]$Folder2)

    $shareFolderFiles = Get-ChildItem -Path $Folder1 
    $localFolderFiles = Get-ChildItem -Path $Folder2

    #if one folder is empty and the other isn't... copy all over. 
    if(($shareFolderFiles | Measure-Object).Count -eq 0){
        if(($localFolderFiles | Measure-Object).Count -ne 0){
            $localFolderFiles | Copy-Item -Destination $Folder1 -Recurse
            return
        }else{
            #both are empty...
            return
        }
    }
    #folder1 is not empty
    if(($localFolderFiles | Measure-Object).Count -eq 0){
            $shareFolderFiles | Copy-Item -Destination $Folder2 -Recurse
            return
    }
    #folder2 is also not empty, continue


    # This part of the script simply checks for file existence in both locations. Once I know each folder at least a version 
    $fileDiffs = Compare-Object -ReferenceObject $shareFolderFiles -DifferenceObject $localFolderFiles -IncludeEqual 
    Foreach($fileComparison in $fileDiffs){
        #get -path 
        $copyParams = @{
            'Path' = $fileComparison.InputObject.FullName
        }
        if($fileComparison.SideIndicator -eq '<='){
            $copyParams.Destination = $localFolder
            Copy-Item @copyParams
            echo $fileComparison.InputObject.FullName copied to $localFolder
        }elseif ($fileComparison.SideIndicator -eq '=>'){
            $copyParams.Destination = $shareFolder
            Copy-Item @copyParams
            echo $fileComparison.InputObject.FullName copied to $ShareFolder
        }
        #if last copied item is a directory, recurse!
        if((Get-Item $fileComparison.InputObject.FullName) -is [System.IO.DirectoryInfo]){
            #syncdir the current subdirectory
            syncDir (join-path $Folder1 $fileComparison.InputObject.Name) (join-path $Folder2 $fileComparison.InputObject.Name) 
        }
    }

    # Once the file exists in both places, get accurate listing 
    $shareFolderFiles = Get-ChildItem -Path $shareFolder
    # Version Checking
    Foreach($file in $shareFolderFiles){
        #show me the file name
        $file.name 
        #if(!(Test-Path -Path (join-path $localFolder $file.name))){    echo false    }  #test if exists in both another way, not used because it doesn't accurately get all files.
        #determine hash of both sides.  if same, skip regardless of last write time. If different, overwrite based on last write time. 
        if((Get-FileHash (join-path $localFolder $file)).Hash -eq (Get-FileHash (join-path $shareFolder $file)).Hash){
            echo same-hash 
        }else{
            #hashes are different, select newest write time and copy that file both places. 
            if((join-path $shareFolder $file).LastWriteTime -gt (join-path $localFolder $file).LastWriteTime){
                Copy-Item -path (join-path $localFolder $file) -Destination $shareFolder -Force
            }else{
                Copy-Item -path (join-path $shareFolder $file) -Destination $localFolder -Force
            }
        }
    }
}

syncDir $shareFolder $localFolder
