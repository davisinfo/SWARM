@echo off

REM ************QUICK ARGUMENTS CHEAT SHEET**************************************************
REM Rigname: Name of your rig
REM Currency: Preferred Fiat Currency
REM CoinExchange: AltCoin Coin Pricing (Besides BTC).
REM Location: EUROPE ASIA US (Choose one).
REM Poolname: Remove Pools As You See Fit. Add Custom Pools If You Like.
REM Type: NVIDIA1 or AMD1 or AMD1,NVIDIA2 or NVIDIA1,NVIDIA2,NVIDIA3 (maximum of three)
REM Wallet1: Your BTC Wallet. Add -Wallet2 or -Wallet3 if using -Type NVIDIA2 or NVIDIA3
REM Donate: Donation in percent
REM WattOMeter: Use Watt Calculations (Default is 0.10 / kwh). Can be modified. See Wiki
REM Farm_Hash: HiveOS Farm Hash

REM ************NOTE***********************
REM If you do not intend to use HiveOS, add -HiveOS No
REM FOR ALL ARGUMENTS: SEE help folder. Explanation on how to use -Type NVIDIA1,NVIDIA2,NVIDIA3 is provided.

powershell -executionpolicy Bypass -command ".\startup.ps1 -RigName1 SERVER08 -Currency USD -CoinExchange BTC -Location EUROPE -PoolName hashrefinery,starpool,fairpool,nicehash,nlpool,phiphipool,zpool,ahashpool,whalesburg,zergpool -Type AMD1 -Wallet1 1MGwuGQrAVLa8XCMAXJ6FcUJ1kmWvYMtxT -Donate .5 -WattOMeter No -platform windows -Farm_Hash 463753fb9d12d8bb4415a37c6a15fbe6aef6b56c -SWARM_Mode Yes -ETH 0x5146cda01a47B0168311DA2c56A3aB5d941BF8C5 -Worker SERVER08 -Nicehash_Wallet1 3CJFwLJVg7ZREAmD1kNPZypCx4PDUZuvGh -Switch_Threshold 3 -Stat_Algo Minute_10 -StatsInterval 1000"