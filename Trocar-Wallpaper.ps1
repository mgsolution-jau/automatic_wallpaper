# ==============================================================================
# Script MG Solution: Wallpaper Automático via API Wallhaven
# ==============================================================================

# 1. Configurações da Logo
$CaminhoLogo = "C:\Scripts\logo.png"
$Opacidade = 0.65
$TamanhoLogo = 0.06

# 2. Obtém a resolução real do monitor principal
Add-Type -AssemblyName System.Windows.Forms
$Width = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$Height = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
$Resolution = "${Width}x${Height}"

# 3. Define os temas desejados
$Temas = @("city", "landscape", "photography", "panorama", "architecture")
$BuscaAleatoria = $Temas | Get-Random

# 4. Constrói a URL da API do Wallhaven
# categories=100 : Apenas imagens Gerais (exclui animes e pessoas/modelos)
# purity=100     : Apenas imagens SFW (Safe For Work / Corporativo)
# sorting=random : Traz resultados aleatórios
# atleast        : Garante que a imagem tenha no mínimo a resolução do monitor
$ApiUrl = "https://wallhaven.cc/api/v1/search?q=$BuscaAleatoria&categories=100&purity=100&sorting=random&atleast=$Resolution"

try {
    # 5. Consulta a API (retorna dados estruturados de forma limpa)
    $Resposta = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing
    
    if ($Resposta.data.Count -eq 0) { 
        throw "Nenhuma imagem encontrada para o tema '$BuscaAleatoria' nesta resolução." 
    }
    
    # Extrai o link direto do arquivo .jpg ou .png
    $FinalImageUrl = $Resposta.data[0].path

    # 6. Faz o download da imagem
    $ImagemOriginal = "$env:TEMP\wp_original_$($PID).jpg"
    $ImagemFinal = "$env:TEMP\wp_com_logo_$($PID).jpg"
    
    Invoke-WebRequest -Uri $FinalImageUrl -OutFile $ImagemOriginal -UseBasicParsing

    # 7. Processamento: Recorta a imagem para o monitor e mescla a logo
    if (Test-Path $CaminhoLogo) {
        Add-Type -AssemblyName System.Drawing
        
        $ImgBaixada = [System.Drawing.Image]::FromFile($ImagemOriginal)
        $ImgLogo = [System.Drawing.Image]::FromFile($CaminhoLogo)
        
        # 7.1 Cria uma tela (Canvas) em branco com a resolução exata do monitor
        $ImgFinalScreen = New-Object System.Drawing.Bitmap($Width, $Height)
        $Graphics = [System.Drawing.Graphics]::FromImage($ImgFinalScreen)
        $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        
        # 7.2 Calcula a proporção para preencher a tela sem distorcer (O mesmo que o "Preencher" do Windows)
        $RatioX = $Width / $ImgBaixada.Width
        $RatioY = $Height / $ImgBaixada.Height
        $Ratio = [math]::Max($RatioX, $RatioY)
        
        $ScaledWidth = $ImgBaixada.Width * $Ratio
        $ScaledHeight = $ImgBaixada.Height * $Ratio
        
        # Centraliza o corte
        $PosX = ($Width - $ScaledWidth) / 2
        $PosY = ($Height - $ScaledHeight) / 2
        
        # Desenha a foto baixada na nossa tela exata (cortando as sobras do fundo)
        $Graphics.DrawImage($ImgBaixada, $PosX, $PosY, $ScaledWidth, $ScaledHeight)
        
        # 7.3 Calcula o tamanho e a posição da Logo baseada na RESOLUÇÃO DA TELA
        $NovaLarguraLogo = [math]::Round($Width * $TamanhoLogo)
        $NovaAlturaLogo = [math]::Round(($ImgLogo.Height * $NovaLarguraLogo) / $ImgLogo.Width)
        
        $MargemDireita = [math]::Round($Width * 0.03)
        $MargemInferior = [math]::Round($Height * 0.08)
        
        $EixoX = $Width - $NovaLarguraLogo - $MargemDireita
        $EixoY = $Height - $NovaAlturaLogo - $MargemInferior
        
        # 7.4 Aplica a transparência na Logo
        $ColorMatrix = New-Object System.Drawing.Imaging.ColorMatrix
        $ColorMatrix.Matrix33 = $Opacidade
        $ImageAttributes = New-Object System.Drawing.Imaging.ImageAttributes
        $ImageAttributes.SetColorMatrix($ColorMatrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)
        
        $DestRect = New-Object System.Drawing.Rectangle($EixoX, $EixoY, $NovaLarguraLogo, $NovaAlturaLogo)
        
        # Desenha a Logo por cima da foto redimensionada
        $Graphics.DrawImage($ImgLogo, $DestRect, 0, 0, $ImgLogo.Width, $ImgLogo.Height, [System.Drawing.GraphicsUnit]::Pixel, $ImageAttributes)
        
        # Salva o arquivo perfeitamente ajustado
        $ImgFinalScreen.Save($ImagemFinal, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        
        # Limpa tudo da memória
        $Graphics.Dispose()
        $ImageAttributes.Dispose()
        $ImgLogo.Dispose()
        $ImgBaixada.Dispose()
        $ImgFinalScreen.Dispose()
        
        $WallpaperParaAplicar = $ImagemFinal
    } else {
        $WallpaperParaAplicar = $ImagemOriginal
    }

    # 8. Força a atualização do papel de parede no Windows
    $CSharpCode = @'
using System.Runtime.InteropServices;
public class WallpaperUpdater {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    Add-Type -TypeDefinition $CSharpCode -ErrorAction SilentlyContinue
    
    [WallpaperUpdater]::SystemParametersInfo(0x0014, 0, $WallpaperParaAplicar, 0x0001 -bor 0x0002)

    if (Test-Path $ImagemOriginal) { Remove-Item $ImagemOriginal -Force -ErrorAction SilentlyContinue }
	
	# Limpa imagens antigas geradas pelo script (mantém apenas a que acabou de ser aplicada)
    Get-ChildItem -Path "$env:TEMP\wp_com_logo_*.jpg" | Where-Object { $_.FullName -ne $ImagemFinal } | Remove-Item -Force -ErrorAction SilentlyContinue
	
    Write-Output "Sucesso! Papel de parede da API Wallhaven aplicado com a logo."

} catch {
    Write-Output "Erro ao trocar o wallpaper via Wallhaven: $_"
}