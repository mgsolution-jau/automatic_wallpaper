# ==============================================================================
# Script MG Solution: Wallpaper Automático (Fonte: GitHub API) + Logo
# ==============================================================================

# 1. Configurações da Logo e Visual
$CaminhoLogo = "C:\Scripts\logo.png"
$Opacidade = 0.85       
$TamanhoLogo = 0.06     

# 2. Obtém a resolução real do monitor
Add-Type -AssemblyName System.Windows.Forms
$Width = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$Height = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# 3. Configurações do GitHub (PREENCHA COM SEUS DADOS)
$GitHubUser = "mgsolution-jau"
$GitHubRepo = "automatic_wallpaper"
$ApiUrl = "https://api.github.com/repos/$GitHubUser/$GitHubRepo/contents/wallpapers"

try {
    # 4. Acessa a API do GitHub para listar todos os arquivos do repositório
    $Resposta = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing
    
    # Filtra apenas os arquivos que são imagens (.jpg, .jpeg ou .png)
    $Imagens = $Resposta | Where-Object { $_.name -match '\.(jpg|jpeg|png)$' }
    
    if ($Imagens.Count -eq 0) { 
        throw "Nenhuma imagem encontrada no repositório do GitHub." 
    }
    
    # Escolhe uma imagem aleatória da lista
    $ImagemEscolhida = $Imagens | Get-Random
    
    # Pega o link direto de download fornecido pela própria API
    $FinalImageUrl = $ImagemEscolhida.download_url

    # 5. Faz o download da imagem
    $ImagemOriginal = "$env:TEMP\wp_original_$($PID).jpg"
    $ImagemFinal = "$env:TEMP\wp_com_logo_$($PID).jpg"
    
    Invoke-WebRequest -Uri $FinalImageUrl -OutFile $ImagemOriginal -UseBasicParsing

    # 6. Processamento: Recorta para o monitor e aplica a logo proporcional
    if (Test-Path $CaminhoLogo) {
        Add-Type -AssemblyName System.Drawing
        
        $ImgBaixada = [System.Drawing.Image]::FromFile($ImagemOriginal)
        $ImgLogo = [System.Drawing.Image]::FromFile($CaminhoLogo)
        
        $ImgFinalScreen = New-Object System.Drawing.Bitmap($Width, $Height)
        $Graphics = [System.Drawing.Graphics]::FromImage($ImgFinalScreen)
        $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        
        $RatioX = $Width / $ImgBaixada.Width
        $RatioY = $Height / $ImgBaixada.Height
        $Ratio = [math]::Max($RatioX, $RatioY)
        
        $ScaledWidth = $ImgBaixada.Width * $Ratio
        $ScaledHeight = $ImgBaixada.Height * $Ratio
        
        $PosX = ($Width - $ScaledWidth) / 2
        $PosY = ($Height - $ScaledHeight) / 2
        
        $Graphics.DrawImage($ImgBaixada, $PosX, $PosY, $ScaledWidth, $ScaledHeight)
        
        $NovaLarguraLogo = [math]::Round($Width * $TamanhoLogo)
        $NovaAlturaLogo = [math]::Round(($ImgLogo.Height * $NovaLarguraLogo) / $ImgLogo.Width)
        
        $MargemDireita = [math]::Round($Width * 0.03)
        $MargemInferior = [math]::Round($Height * 0.08)
        
        $EixoX = $Width - $NovaLarguraLogo - $MargemDireita
        $EixoY = $Height - $NovaAlturaLogo - $MargemInferior
        
        $ColorMatrix = New-Object System.Drawing.Imaging.ColorMatrix
        $ColorMatrix.Matrix33 = $Opacidade
        $ImageAttributes = New-Object System.Drawing.Imaging.ImageAttributes
        $ImageAttributes.SetColorMatrix($ColorMatrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)
        
        $DestRect = New-Object System.Drawing.Rectangle($EixoX, $EixoY, $NovaLarguraLogo, $NovaAlturaLogo)
        $Graphics.DrawImage($ImgLogo, $DestRect, 0, 0, $ImgLogo.Width, $ImgLogo.Height, [System.Drawing.GraphicsUnit]::Pixel, $ImageAttributes)
        
        $ImgFinalScreen.Save($ImagemFinal, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        
        $Graphics.Dispose()
        $ImageAttributes.Dispose()
        $ImgLogo.Dispose()
        $ImgBaixada.Dispose()
        $ImgFinalScreen.Dispose()
        
        $WallpaperParaAplicar = $ImagemFinal
    } else {
        $WallpaperParaAplicar = $ImagemOriginal
    }

    # 7. Força a atualização do papel de parede via API nativa do Windows
    $CSharpCode = @'
using System.Runtime.InteropServices;
public class WallpaperUpdater {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    Add-Type -TypeDefinition $CSharpCode -ErrorAction SilentlyContinue
    [WallpaperUpdater]::SystemParametersInfo(0x0014, 0, $WallpaperParaAplicar, 0x0001 -bor 0x0002)

    # 8. Limpeza de arquivos temporários antigos
    if (Test-Path $ImagemOriginal) { Remove-Item $ImagemOriginal -Force -ErrorAction SilentlyContinue }
    Get-ChildItem -Path "$env:TEMP\wp_com_logo_*.jpg" | Where-Object { $_.FullName -ne $ImagemFinal } | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Output "Sucesso! Papel de parede atualizado a partir do GitHub."

} catch {
    Write-Output "Erro ao trocar o wallpaper via GitHub: $_"
}
