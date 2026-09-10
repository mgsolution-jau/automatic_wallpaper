@echo off
title Instalador Online MG Solution - Tarefa Wallpaper
color 0B

echo Verificando privilegios de Administrador...
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 4F
    echo =======================================================
    echo ERRO: O SCRIPT NAO FOI EXECUTADO COMO ADMINISTRADOR!
    echo =======================================================
    echo Por favor, clique com o BOTAO DIREITO neste arquivo
    echo e selecione "Executar como administrador".
    echo =======================================================
    pause
    exit /b
)

echo Privilegios confirmados! 
echo.
echo =======================================================
echo 1. Sincronizando arquivos com o servidor da MG Solution...
echo =======================================================

:: Garante que a pasta C:\Scripts existe na maquina do cliente
if not exist "C:\Scripts" mkdir "C:\Scripts"

:: ==============================================================================
:: COLOQUE AQUI OS SEUS LINKS RAW DO GITHUB
:: ==============================================================================
set "URL_PS1=https://raw.githubusercontent.com/mgsolution-jau/automatic_wallpaper/refs/heads/main/Trocar-Wallpaper.ps1"
set "URL_LOGO=https://raw.githubusercontent.com/mgsolution-jau/automatic_wallpaper/main/logo.png"

:: Baixa os arquivos direto para o computador do cliente
powershell -Command "Invoke-WebRequest -Uri '%URL_PS1%' -OutFile 'C:\Scripts\Trocar-Wallpaper.ps1' -UseBasicParsing"
powershell -Command "Invoke-WebRequest -Uri '%URL_LOGO%' -OutFile 'C:\Scripts\logo.png' -UseBasicParsing"

echo Download concluido com sucesso!
echo.
echo 2. Criando o motor VBScript invisivel...

:: Cria o arquivo Invisivel.vbs na mesma pasta dos scripts
echo Set objShell = CreateObject("WScript.Shell") > "C:\Scripts\Invisivel.vbs"
echo objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Scripts\Trocar-Wallpaper.ps1""", 0, False >> "C:\Scripts\Invisivel.vbs"

echo.
echo 3. Atualizando a tarefa agendada no Windows...

:: Atualiza a tarefa para executar o WScript silenciosamente a cada 45 minutos
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$Acao = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument 'C:\Scripts\Invisivel.vbs'; $Rep = New-ScheduledTaskTrigger -Once -At '00:00' -RepetitionInterval (New-TimeSpan -Minutes 45); $Gatilho = New-ScheduledTaskTrigger -AtLogon; $Gatilho.Repetition = $Rep.Repetition; $Config = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable; Register-ScheduledTask -TaskName 'MGSolution_Wallpaper' -Action $Acao -Trigger $Gatilho -Settings $Config -Description 'Troca automatica de Wallpaper (45 min) - Invisivel' -Force"

echo.
echo =======================================================
echo SUCESSO! Ambiente configurado e atualizado.
echo =======================================================
echo O terminal ja esta pronto e operando de forma invisivel.
echo Pressione qualquer tecla para fechar.
pause >nul
