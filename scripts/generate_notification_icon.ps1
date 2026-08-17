# Genera l'icona monocroma per la notifica (silhouette bianca della "S" su
# sfondo trasparente), richiesta da Android per le icone nella status bar.
# Va rilanciato solo se si vuole rigenerare/modificare l'icona.

Add-Type -AssemblyName System.Drawing

$sizes = @{
    'drawable-mdpi'    = 24
    'drawable-hdpi'     = 36
    'drawable-xhdpi'    = 48
    'drawable-xxhdpi'   = 72
    'drawable-xxxhdpi'  = 96
}

$resRoot = Join-Path $PSScriptRoot '..\android\app\src\main\res'

foreach ($dir in $sizes.Keys) {
    $size = $sizes[$dir]
    $outDir = Join-Path $resRoot $dir
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $outPath = Join-Path $outDir 'ic_stat_notify.png'

    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $fontSize = [float]($size * 0.72)
    $font = New-Object System.Drawing.Font('Arial', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = [System.Drawing.Brushes]::White
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center

    $rect = New-Object System.Drawing.RectangleF 0, 0, $size, $size
    $g.DrawString('S', $font, $brush, $rect, $format)

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Creato $outPath ($size x $size)"
}
