cd "C:\Paxis"
dir | ? { $_.LastWriteTime -gt '5/2/23 4:00:00 PM' -AND $_.LastWriteTime -lt '5/2/23 5:00:00 PM'}