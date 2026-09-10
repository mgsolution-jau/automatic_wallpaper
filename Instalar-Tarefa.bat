@echo off
title Instalador MG Solution - Tarefa Wallpaper
color 0B

echo Verificando privilegios...
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 4F
    echo =======================================================
    echo ERRO: O SCRIPT NAO FOI EXECUTADO COMO ADMINISTRADOR!
    echo =======================================================
    echo Por favor, feche esta janela.
    echo Clique com o BOTAO DIREITO no arquivo Instalar-Tarefa.bat
    echo e selecione "Executar como administrador".
    echo =======================================================
    pause
    exit /b
)

echo.
echo =======================================================
echo Privilegios confirmados! 
echo =======================================================
echo.
echo 1. Criando o motor VBScript invisivel...

:: Cria o arquivo Invisivel.vbs na mesma pasta dos scripts
echo Set objShell = CreateObject("WScript.Shell") > "C:\Scripts\Invisivel.vbs"
echo objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Scripts\Trocar-Wallpaper.ps1""", 0, False >> "C:\Scripts\Invisivel.vbs"

echo 2. Atualizando a tarefa agendada...
echo.

:: Atualiza a tarefa para executar o WScript (que roda o VBS) em vez de chamar o PowerShell direto
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$Acao = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument 'C:\Scripts\Invisivel.vbs'; $Rep = New-ScheduledTaskTrigger -Once -At '00:00' -RepetitionInterval (New-TimeSpan -Minutes 45); $Gatilho = New-ScheduledTaskTrigger -AtLogon; $Gatilho.Repetition = $Rep.Repetition; $Config = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable; Register-ScheduledTask -TaskName 'MGSolution_Wallpaper' -Action $Acao -Trigger $Gatilho -Settings $Config -Description 'Troca automatica de Wallpaper MG Solution (45 min) - Invisivel' -Force"

echo.
echo =======================================================
echo Verificando se a tarefa foi criada com sucesso:
echo =======================================================
powershell.exe -Command "Get-ScheduledTask -TaskName 'MGSolution_Wallpaper' -ErrorAction SilentlyContinue | Format-Table TaskName, State"

echo.
echo Instalacao concluida! A partir de agora, a troca sera completamente invisivel.
echo Pressione qualquer tecla para fechar.
pause >nul