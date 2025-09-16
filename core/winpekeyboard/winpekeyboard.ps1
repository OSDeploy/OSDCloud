if (Get-Command -Name 'osk.exe') {
    Start-Process -FilePath 'osk.exe' -WindowStyle Minimized
}