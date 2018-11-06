#usefull to change creation date of package directories

$FilesInTemp = Get-ChildItem “C:\temp2” #Directory to edit


foreach($file in $FilesInTemp){
    $file.LastWriteTime = Get-Date “11/5/2018 8:06 AM” #new last write time
    $file.CreationTime = Get-Date “11/5/2018 8:06 AM” #new last write time
}


$FilesInTemp#echo to check