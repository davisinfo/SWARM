$host.ui.RawUI.WindowTitle = 'OC-Start';
Invoke-Expression '.\nvidiaInspector.exe -setPowerTarget:0,75  -setFanSpeed:0,75  -setMemoryClockOffset:0,0,500  -setBaseClockOffset:0,0,100 '
