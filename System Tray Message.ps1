[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon

$objNotifyIcon.Icon = "C:\Windows\temp\ftp\pax_icon_yellow.ico"
$objNotifyIcon.BalloonTipIcon = "Warning"
$objNotifyIcon.BalloonTipText = "Your machine has updated and needs to reboot."
$objNotifyIcon.BalloonTipTitle = "Please Reboot"

$objNotifyIcon.Visible = $True
$objNotifyIcon.ShowBalloonTip(30000)