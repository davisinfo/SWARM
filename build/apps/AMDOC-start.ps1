$host.ui.RawUI.WindowTitle = 'OC-Start';
Start-Process ".\OverdriveNTool.exe" -ArgumentList "-ac1 Mem_TimingLevel=0 Mem_P3=950;950 Fan_P0=80;70 Fan_P1=80;70 Fan_P2=80;70 Fan_P3=80;70 Fan_P4=80;70 GPU_P7=1700;1250 " -Wait
Start-Process ".\OverdriveNTool.exe" -ArgumentList "-ac2 Mem_TimingLevel=0 Mem_P2=2000;950 Fan_P0=80;60 Fan_P1=80;60 Fan_P2=80;60 Fan_P3=80;60 Fan_P4=80;60 GPU_P7=1350;1150 " -Wait
