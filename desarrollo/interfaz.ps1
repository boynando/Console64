Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==============================================================================
# API NATIVA DE WINDOWS PARA MANDOS Y TITULOS
# ==============================================================================
$codigoWin32 = @"
using System;
using System.Runtime.InteropServices;

public class Win32N64 {
    [DllImport("user32.dll")]
    public static extern bool SetWindowText(IntPtr hwnd, String lpString);

    [DllImport("winmm.dll")]
    public static extern int joyGetNumDevs();

    [DllImport("winmm.dll")]
    public static extern int joyGetPosEx(int uJoyID, ref JOYINFOEX pji);

    [StructLayout(LayoutKind.Sequential)]
    public struct JOYINFOEX {
        public int dwSize;
        public int dwFlags;
        public int dwXpos;
        public int dwYpos;
        public int dwZpos;
        public int dwRpos;
        public int dwUpos;
        public int dwVpos;
        public int dwButtons;
        public int dwButtonNumber;
        public int dwPOV;
        public int dwReserved1;
        public int dwReserved2;
    }

    public static JOYINFOEX LeerMando(int id) {
        JOYINFOEX info = new JOYINFOEX();
        info.dwSize = Marshal.SizeOf(typeof(JOYINFOEX));
        info.dwFlags = 255;
        int res = joyGetPosEx(id, ref info);
        if (res != 0) info.dwSize = -1;
        return info;
    }
}
"@
Add-Type -TypeDefinition $codigoWin32

# ==============================================================================
# 1. DESCARGAR LOGO OFICIAL DE CONSOLE 64
# ==============================================================================
$urlIcono = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTkpoW5-3QQKN1P3hbZ1r1gV8gxKRA2_bz_mFDcvy6cOA&s=10"
$rutaTempIcono = "$env:TEMP\console64_logo.png"
$imgMandoGlobal = $null
$iconoApp = $null

try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($urlIcono, $rutaTempIcono)
    $imgOriginal = [System.Drawing.Image]::FromFile($rutaTempIcono)
    
    $bmpIcono = New-Object System.Drawing.Bitmap(32, 32)
    $gImg = [System.Drawing.Graphics]::FromImage($bmpIcono)
    $gImg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gImg.DrawImage($imgOriginal, 0, 0, 32, 32)
    $gImg.Dispose()
    $iconoApp = [System.Drawing.Icon]::FromHandle($bmpIcono.GetHicon())

    $imgMandoGlobal = [System.Drawing.Image]::FromFile($rutaTempIcono)
    $imgOriginal.Dispose()
} catch {
    $bmpIcono = New-Object System.Drawing.Bitmap(32, 32)
}

# ==============================================================================
# 2. PANTALLA DE BIENVENIDA CON CUENTA REGRESIVA (20 SEGUNDOS)
# ==============================================================================
$splashForm = New-Object System.Windows.Forms.Form
$splashForm.Text = "Console64 - Bienvenido"
$splashForm.Size = New-Object System.Drawing.Size(500, 420)
$splashForm.StartPosition = "CenterScreen"
$splashForm.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 34)
$splashForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$splashForm.MaximizeBox = $false
$splashForm.MinimizeBox = $false
if ($iconoApp) { $splashForm.Icon = $iconoApp }

$picSplashLogo = New-Object System.Windows.Forms.PictureBox
$picSplashLogo.Size = New-Object System.Drawing.Size(130, 130)
$picSplashLogo.Location = New-Object System.Drawing.Point(175, 25)
$picSplashLogo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
if ($imgMandoGlobal) { $picSplashLogo.Image = $imgMandoGlobal }
$splashForm.Controls.Add($picSplashLogo)

$lblMensajeSplash = New-Object System.Windows.Forms.Label
$lblMensajeSplash.Text = "Hola se que te molestara esta pantalla de inicio pero espera unos segundos por que el emulador es gratis y tambien actualizaciones gratis"
$lblMensajeSplash.ForeColor = [System.Drawing.Color]::White
$lblMensajeSplash.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Regular)
$lblMensajeSplash.Location = New-Object System.Drawing.Point(35, 170)
$lblMensajeSplash.Size = New-Object System.Drawing.Size(415, 70)
$lblMensajeSplash.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$splashForm.Controls.Add($lblMensajeSplash)

$script:segundosRestantes = 20
$lblContador = New-Object System.Windows.Forms.Label
$lblContador.Text = "20 segundos"
$lblContador.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 255)
$lblContador.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblContador.Location = New-Object System.Drawing.Point(35, 250)
$lblContador.Size = New-Object System.Drawing.Size(415, 35)
$lblContador.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$splashForm.Controls.Add($lblContador)

$btnContinue = New-Object System.Windows.Forms.Button
$btnContinue.Text = "Continue"
$btnContinue.Location = New-Object System.Drawing.Point(165, 305)
$btnContinue.Size = New-Object System.Drawing.Size(155, 42)
$btnContinue.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$btnContinue.ForeColor = [System.Drawing.Color]::White
$btnContinue.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnContinue.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnContinue.Visible = $false
$btnContinue.Enabled = $false

$script:usuarioContinuo = $false
$btnContinue.Add_Click({
    $script:usuarioContinuo = $true
    $splashForm.Close()
})
$splashForm.Controls.Add($btnContinue)

$timerSplash = New-Object System.Windows.Forms.Timer
$timerSplash.Interval = 1000
$timerSplash.Add_Tick({
    $script:segundosRestantes--
    if ($script:segundosRestantes -gt 0) {
        $lblContador.Text = "$($script:segundosRestantes) segundos"
    } else {
        $timerSplash.Stop()
        $lblContador.Text = "0 segundos"
        $lblContador.ForeColor = [System.Drawing.Color]::LightGreen
        $btnContinue.Visible = $true
        $btnContinue.Enabled = $true
    }
})
$timerSplash.Start()

$splashForm.Add_FormClosing({ $timerSplash.Stop() })
[void]$splashForm.ShowDialog()

if (-not $script:usuarioContinuo) { exit }

# ==============================================================================
# 3. VENTANA PRINCIPAL DE CONSOLE 64
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Console64 - Emulador de Nintendo 64"
$form.Size = New-Object System.Drawing.Size(700, 520)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
if ($iconoApp) { $form.Icon = $iconoApp }

# MENU SUPERIOR
$menuStrip = New-Object System.Windows.Forms.MenuStrip

$menuArchivo = New-Object System.Windows.Forms.ToolStripMenuItem("Archivo")
$itemAbrir = New-Object System.Windows.Forms.ToolStripMenuItem("Abrir ROM...")
$itemRefrescar = New-Object System.Windows.Forms.ToolStripMenuItem("Actualizar Lista")
$itemSalir = New-Object System.Windows.Forms.ToolStripMenuItem("Salir")
$itemSalir.Add_Click({ $form.Close() })
$menuArchivo.DropDownItems.AddRange(@($itemAbrir, $itemRefrescar, $itemSalir))

$menuOpciones = New-Object System.Windows.Forms.ToolStripMenuItem("Opciones")
$itemControles = New-Object System.Windows.Forms.ToolStripMenuItem("Configurar Controles (Estilo Project64)...")
$itemGraficos = New-Object System.Windows.Forms.ToolStripMenuItem("Configurar Graficos (Graphics Select)...")
$itemAudio = New-Object System.Windows.Forms.ToolStripMenuItem("Configurar Audio (Sound Select)...")
$sep1 = New-Object System.Windows.Forms.ToolStripSeparator
$itemCarpetaRoms = New-Object System.Windows.Forms.ToolStripMenuItem("Abrir Carpeta ROMs")
$itemCarpetaCore = New-Object System.Windows.Forms.ToolStripMenuItem("Abrir Carpeta Core")
$menuOpciones.DropDownItems.AddRange(@($itemControles, $itemGraficos, $itemAudio, $sep1, $itemCarpetaRoms, $itemCarpetaCore))

$menuStrip.Items.AddRange(@($menuArchivo, $menuOpciones))
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

# CABECERA
$panelHeader = New-Object System.Windows.Forms.Panel
$panelHeader.Location = New-Object System.Drawing.Point(0, 24)
$panelHeader.Size = New-Object System.Drawing.Size(700, 65)
$panelHeader.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 36)
$form.Controls.Add($panelHeader)

$picLogo = New-Object System.Windows.Forms.PictureBox
$picLogo.Image = $bmpIcono
$picLogo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$picLogo.Location = New-Object System.Drawing.Point(15, 10)
$picLogo.Size = New-Object System.Drawing.Size(44, 44)
$panelHeader.Controls.Add($picLogo)

$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text = "CONSOLE 64"
$lblTitulo.ForeColor = [System.Drawing.Color]::White
$lblTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$lblTitulo.Location = New-Object System.Drawing.Point(72, 10)
$lblTitulo.AutoSize = $true
$panelHeader.Controls.Add($lblTitulo)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Emulador Nativo de Nintendo 64"
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.Location = New-Object System.Drawing.Point(74, 38)
$lblSub.AutoSize = $true
$panelHeader.Controls.Add($lblSub)

# LISTA DE JUEGOS
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(15, 100)
$listView.Size = New-Object System.Drawing.Size(655, 345)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)

[void]$listView.Columns.Add("Nombre del Juego", 400)
[void]$listView.Columns.Add("Formato", 95)
[void]$listView.Columns.Add("Tamano", 135)
$form.Controls.Add($listView)

$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel("Listo para jugar...")
[void]$statusBar.Items.Add($statusLabel)
$form.Controls.Add($statusBar)

# Rutas
$rutaRoms = Join-Path $PSScriptRoot "..\almacen\ROMs"
$rutaCore = Join-Path $PSScriptRoot "..\almacen\Core"
$rutaConfigLocal = Join-Path $PSScriptRoot "..\almacen\Configs"

function Cargar-Biblioteca {
    $listView.Items.Clear()
    if (Test-Path $rutaRoms) {
        $roms = Get-ChildItem -Path $rutaRoms -Include *.z64, *.n64, *.v64 -Recurse
        foreach ($rom in $roms) {
            $tamanoMB = "{0:N2} MB" -f ($rom.Length / 1MB)
            $item = New-Object System.Windows.Forms.ListViewItem($rom.BaseName)
            [void]$item.SubItems.Add($rom.Extension.ToUpper())
            [void]$item.SubItems.Add($tamanoMB)
            $item.Tag = $rom.FullName
            [void]$listView.Items.Add($item)
        }
        $statusLabel.Text = "Juegos encontrados: $($roms.Count)"
    }
}

# OBTENER NOMBRE REAL DE LOS MANDOS
function Obtener-MandosReales {
    $mandos = @()
    for ($i = 0; $i -lt 4; $i++) {
        $estado = [Win32N64]::LeerMando($i)
        if ($estado.dwSize -ne -1) {
            $nombreReal = "Mando USB Puerto $($i + 1)"
            try {
                $rutaReg = "HKCU:\System\CurrentControlSet\Control\MediaResources\Joystick\DINPUT.DLL\CurrentJoystickSettings"
                $oemKey = (Get-ItemProperty -Path $rutaReg -ErrorAction SilentlyContinue)."Joystick$($i + 1)OEMName"
                if ($oemKey) {
                    $oemData = Get-ItemProperty -Path "HKCU:\System\CurrentControlSet\Control\MediaProperties\PrivateProperties\Joystick\OEM\$oemKey" -ErrorAction SilentlyContinue
                    if ($oemData.OEMName) { $nombreReal = $oemData.OEMName }
                }
            } catch {}
            $mandos += @{ Id = $i; Nombre = $nombreReal }
        }
    }
    return $mandos
}

# ==============================================================================
# 4. VENTANA DE CONFIGURACION DE GRAFICOS (RENDIMIENTO MÁXIMO)
# ==============================================================================
$itemGraficos.Add_Click({
    $grafForm = New-Object System.Windows.Forms.Form
    $grafForm.Text = "Console64 - Graphics Select (Rendimiento o Calidad)"
    $grafForm.Size = New-Object System.Drawing.Size(420, 310)
    $grafForm.StartPosition = "CenterParent"
    $grafForm.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 48)
    $grafForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $grafForm.MaximizeBox = $false
    if ($iconoApp) { $grafForm.Icon = $iconoApp }

    $lblGrafTitulo = New-Object System.Windows.Forms.Label
    $lblGrafTitulo.Text = "Selecciona el perfil gráfico del emulador:"
    $lblGrafTitulo.ForeColor = [System.Drawing.Color]::White
    $lblGrafTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lblGrafTitulo.Location = New-Object System.Drawing.Point(20, 20)
    $lblGrafTitulo.AutoSize = $true
    $grafForm.Controls.Add($lblGrafTitulo)

    $rbRendimiento = New-Object System.Windows.Forms.RadioButton
    $rbRendimiento.Text = "Modo Rendimiento (Ultra Rápido y Fluido)"
    $rbRendimiento.ForeColor = [System.Drawing.Color]::LightGreen
    $rbRendimiento.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $rbRendimiento.Location = New-Object System.Drawing.Point(35, 65)
    $rbRendimiento.AutoSize = $true
    $rbRendimiento.Checked = $true # Marcado por defecto para velocidad máxima
    $grafForm.Controls.Add($rbRendimiento)

    $lblSubRend = New-Object System.Windows.Forms.Label
    $lblSubRend.Text = "Optimizado para velocidad máxima. El juego corre fluido sin caídas de cuadros."
    $lblSubRend.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 190)
    $lblSubRend.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblSubRend.Location = New-Object System.Drawing.Point(55, 92)
    $lblSubRend.Size = New-Object System.Drawing.Size(325, 35)
    $grafForm.Controls.Add($lblSubRend)

    $rbCalidad = New-Object System.Windows.Forms.RadioButton
    $rbCalidad.Text = "Mejor Experiencia (Gráficos Mejorados)"
    $rbCalidad.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 255)
    $rbCalidad.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $rbCalidad.Location = New-Object System.Drawing.Point(35, 140)
    $rbCalidad.AutoSize = $true
    $grafForm.Controls.Add($rbCalidad)

    $lblSubCal = New-Object System.Windows.Forms.Label
    $lblSubCal.Text = "Activa suavizado visual y filtros de alta resolución."
    $lblSubCal.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 190)
    $lblSubCal.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblSubCal.Location = New-Object System.Drawing.Point(55, 167)
    $lblSubCal.Size = New-Object System.Drawing.Size(325, 30)
    $grafForm.Controls.Add($lblSubCal)

    $btnGuardarGraf = New-Object System.Windows.Forms.Button
    $btnGuardarGraf.Text = "Aplicar Perfil Gráfico"
    $btnGuardarGraf.Location = New-Object System.Drawing.Point(105, 215)
    $btnGuardarGraf.Size = New-Object System.Drawing.Size(195, 38)
    $btnGuardarGraf.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnGuardarGraf.ForeColor = [System.Drawing.Color]::White
    $btnGuardarGraf.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnGuardarGraf.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)

    $btnGuardarGraf.Add_Click({
        $esRendimiento = $rbRendimiento.Checked
        if (!(Test-Path $rutaConfigLocal)) { New-Item -ItemType Directory -Path $rutaConfigLocal | Out-Null }
        $archivoCfg = Join-Path $rutaConfigLocal "mupen64plus.cfg"

        $bloqueGraficos = @"
[Video-General]
ScreenWidth = 640
ScreenHeight = 480
VerticalSync = False

[Video-GlideN64]
configVersion = 17
aspect = 1
bilinearMode = $(if ($esRendimiento) { "0" } else { "1" })
enableLegacyBlending = True
multisampling = $(if ($esRendimiento) { "0" } else { "4" })
fxaa = $(if ($esRendimiento) { "False" } else { "True" })
"@

        if (Test-Path $archivoCfg) {
            $contenido = Get-Content $archivoCfg -Raw
            $patron = "(?s)\[Video-General\].*?(?=\r?\n\[|\z)"
            if ($contenido -match $patron) {
                $contenido = [regex]::Replace($contenido, $patron, $bloqueGraficos)
            } else {
                $contenido += "`r`n`r`n$bloqueGraficos"
            }
            Set-Content -Path $archivoCfg -Value $contenido -Encoding ASCII
        } else {
            Set-Content -Path $archivoCfg -Value $bloqueGraficos -Encoding ASCII
        }

        $modoTexto = if ($esRendimiento) { "Modo Rendimiento (Ultra Rápido)" } else { "Mejor Experiencia (Alta Calidad)" }
        [System.Windows.Forms.MessageBox]::Show("¡Perfil aplicado correctamente!`nSeleccionado: $modoTexto", "Console64 - Gráficos", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $grafForm.Close()
    })
    $grafForm.Controls.Add($btnGuardarGraf)

    [void]$grafForm.ShowDialog()
})

# ==============================================================================
# 5. VENTANA DE CONFIGURACION DE AUDIO (SOUND SELECT)
# ==============================================================================
$itemAudio.Add_Click({
    $audioForm = New-Object System.Windows.Forms.Form
    $audioForm.Text = "Console64 - Sound Select (Audio Configuration)"
    $audioForm.Size = New-Object System.Drawing.Size(380, 280)
    $audioForm.StartPosition = "CenterParent"
    $audioForm.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 48)
    $audioForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $audioForm.MaximizeBox = $false
    if ($iconoApp) { $audioForm.Icon = $iconoApp }

    $lblAudioTitulo = New-Object System.Windows.Forms.Label
    $lblAudioTitulo.Text = "Selecciona el modo de salida de sonido:"
    $lblAudioTitulo.ForeColor = [System.Drawing.Color]::White
    $lblAudioTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblAudioTitulo.Location = New-Object System.Drawing.Point(20, 20)
    $lblAudioTitulo.AutoSize = $true
    $audioForm.Controls.Add($lblAudioTitulo)

    $rbStereo = New-Object System.Windows.Forms.RadioButton
    $rbStereo.Text = "Stereo (Recomendado / Alta Fidelidad)"
    $rbStereo.ForeColor = [System.Drawing.Color]::White
    $rbStereo.Location = New-Object System.Drawing.Point(35, 65)
    $rbStereo.AutoSize = $true
    $rbStereo.Checked = $true
    $audioForm.Controls.Add($rbStereo)

    $rbMono = New-Object System.Windows.Forms.RadioButton
    $rbMono.Text = "Mono (Canal unico combinado)"
    $rbMono.ForeColor = [System.Drawing.Color]::White
    $rbMono.Location = New-Object System.Drawing.Point(35, 105)
    $rbMono.AutoSize = $true
    $audioForm.Controls.Add($rbMono)

    $rbHeadset = New-Object System.Windows.Forms.RadioButton
    $rbHeadset.Text = "Headset / Auriculares (Optimizado)"
    $rbHeadset.ForeColor = [System.Drawing.Color]::White
    $rbHeadset.Location = New-Object System.Drawing.Point(35, 145)
    $rbHeadset.AutoSize = $true
    $audioForm.Controls.Add($rbHeadset)

    $btnGuardarAudio = New-Object System.Windows.Forms.Button
    $btnGuardarAudio.Text = "Aplicar Modo de Audio"
    $btnGuardarAudio.Location = New-Object System.Drawing.Point(90, 195)
    $btnGuardarAudio.Size = New-Object System.Drawing.Size(185, 35)
    $btnGuardarAudio.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnGuardarAudio.ForeColor = [System.Drawing.Color]::White
    $btnGuardarAudio.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnGuardarAudio.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

    $btnGuardarAudio.Add_Click({
        $modoAudio = "0"
        if ($rbMono.Checked) { $modoAudio = "1" }
        elseif ($rbHeadset.Checked) { $modoAudio = "2" }

        if (!(Test-Path $rutaConfigLocal)) { New-Item -ItemType Directory -Path $rutaConfigLocal | Out-Null }
        $archivoCfg = Join-Path $rutaConfigLocal "mupen64plus.cfg"

        $bloqueAudio = @"
[Audio-SDL]
version = 1.000000
PRIMARY_BUFFER_SIZE = 16384
SECONDARY_BUFFER_SIZE = 2048
AUDIO_RESAMPLE = "speex"
SWAP_CHANNELS = False
DEFAULT_FREQ = 44100
SOUND_MODE = $modoAudio
"@

        if (Test-Path $archivoCfg) {
            $contenido = Get-Content $archivoCfg -Raw
            $patron = "(?s)\[Audio-SDL\].*?(?=\r?\n\[|\z)"
            if ($contenido -match $patron) {
                $contenido = [regex]::Replace($contenido, $patron, $bloqueAudio)
            } else {
                $contenido += "`r`n`r`n$bloqueAudio"
            }
            Set-Content -Path $archivoCfg -Value $contenido -Encoding ASCII
        } else {
            Set-Content -Path $archivoCfg -Value $bloqueAudio -Encoding ASCII
        }

        [System.Windows.Forms.MessageBox]::Show("¡Modo de sonido aplicado con éxito!", "Console64 - Audio", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $audioForm.Close()
    })
    $audioForm.Controls.Add($btnGuardarAudio)

    [void]$audioForm.ShowDialog()
})

# ==============================================================================
# 6. VENTANA DE CONFIGURACION DE CONTROLES (DOBLE PALANCA Y EJES COMPLETOS)
# ==============================================================================
$itemControles.Add_Click({
    $ctrlForm = New-Object System.Windows.Forms.Form
    $ctrlForm.Text = "Console64 - Configuracion del Mando (Project64 Style)"
    $ctrlForm.Size = New-Object System.Drawing.Size(760, 540)
    $ctrlForm.StartPosition = "CenterParent"
    $ctrlForm.BackColor = [System.Drawing.Color]::FromArgb(235, 235, 240)
    $ctrlForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $ctrlForm.MaximizeBox = $false
    $ctrlForm.KeyPreview = $true

    $mandosConectados = Obtener-MandosReales

    $lblJug = New-Object System.Windows.Forms.Label
    $lblJug.Text = "Jugador:"
    $lblJug.Location = New-Object System.Drawing.Point(20, 18)
    $lblJug.AutoSize = $true
    $ctrlForm.Controls.Add($lblJug)

    $comboJugador = New-Object System.Windows.Forms.ComboBox
    $comboJugador.Location = New-Object System.Drawing.Point(80, 15)
    $comboJugador.Size = New-Object System.Drawing.Size(130, 25)
    $comboJugador.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    [void]$comboJugador.Items.Add("Jugador 1")
    [void]$comboJugador.Items.Add("Jugador 2")
    $comboJugador.SelectedIndex = 0
    $ctrlForm.Controls.Add($comboJugador)

    $lblDisp = New-Object System.Windows.Forms.Label
    $lblDisp.Text = "Dispositivo:"
    $lblDisp.Location = New-Object System.Drawing.Point(230, 18)
    $lblDisp.AutoSize = $true
    $ctrlForm.Controls.Add($lblDisp)

    $comboDisp = New-Object System.Windows.Forms.ComboBox
    $comboDisp.Location = New-Object System.Drawing.Point(305, 15)
    $comboDisp.Size = New-Object System.Drawing.Size(310, 25)
    $comboDisp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    [void]$comboDisp.Items.Add("Teclado de PC")
    foreach ($m in $mandosConectados) {
        [void]$comboDisp.Items.Add("$($m.Nombre) (ID: $($m.Id))")
    }
    if ($mandosConectados.Count -gt 0) { $comboDisp.SelectedIndex = 1 } else { $comboDisp.SelectedIndex = 0 }
    $ctrlForm.Controls.Add($comboDisp)

    $lblEstadoMando = New-Object System.Windows.Forms.Label
    $lblEstadoMando.Location = New-Object System.Drawing.Point(20, 48)
    $lblEstadoMando.Size = New-Object System.Drawing.Size(700, 20)
    $lblEstadoMando.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
    if ($mandosConectados.Count -gt 0) {
        $lblEstadoMando.Text = "Mando detectado: $($mandosConectados[0].Nombre) - Haz clic en un boton y muevelo."
        $lblEstadoMando.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        $lblEstadoMando.Text = "No hay mando conectado. Usando Teclado (Haz clic y presiona una tecla)."
        $lblEstadoMando.ForeColor = [System.Drawing.Color]::DarkRed
    }
    $ctrlForm.Controls.Add($lblEstadoMando)

    $picMandoN64 = New-Object System.Windows.Forms.PictureBox
    $picMandoN64.Location = New-Object System.Drawing.Point(230, 110)
    $picMandoN64.Size = New-Object System.Drawing.Size(280, 270)
    $picMandoN64.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    if ($imgMandoGlobal) {
        $picMandoN64.Image = $imgMandoGlobal
    }
    $ctrlForm.Controls.Add($picMandoN64)

    $script:botonEnEspera = $null
    $script:mapeos = @{
        "StickUp"    = @{ Label = "Palanca Arriba";    X = 15;  Y = 85;  Val = "axis(1-)"; Texto = "Arriba / Y-" }
        "StickDown"  = @{ Label = "Palanca Abajo";     X = 15;  Y = 120; Val = "axis(1+)"; Texto = "Abajo / Y+" }
        "StickLeft"  = @{ Label = "Palanca Izquierda"; X = 15;  Y = 155; Val = "axis(0-)"; Texto = "Izquierda / X-" }
        "StickRight" = @{ Label = "Palanca Derecha";   X = 15;  Y = 190; Val = "axis(0+)"; Texto = "Derecha / X+" }
        "ZTrig"      = @{ Label = "Gatillo Z";         X = 15;  Y = 240; Val = "button(4)"; Texto = "Z / L1" }
        "LTrig"      = @{ Label = "Boton L";           X = 15;  Y = 275; Val = "button(6)"; Texto = "Q / L2" }
        "Start"      = @{ Label = "Start";             X = 15;  Y = 325; Val = "button(7)"; Texto = "Enter" }

        "BtnA"       = @{ Label = "Boton A";           X = 520; Y = 85;  Val = "button(0)"; Texto = "X / Btn 1" }
        "BtnB"       = @{ Label = "Boton B";           X = 520; Y = 120; Val = "button(1)"; Texto = "C / Btn 2" }
        "RTrig"      = @{ Label = "Boton R";           X = 520; Y = 155; Val = "button(5)"; Texto = "E / R1" }
        "CUp"        = @{ Label = "C-Arriba";          X = 520; Y = 205; Val = "axis(3-)"; Texto = "Stick2 Arriba" }
        "CDown"      = @{ Label = "C-Abajo";           X = 520; Y = 240; Val = "axis(3+)"; Texto = "Stick2 Abajo" }
        "CLeft"      = @{ Label = "C-Izquierda";       X = 520; Y = 275; Val = "axis(2-)"; Texto = "Stick2 Izq" }
        "CRight"     = @{ Label = "C-Derecha";         X = 520; Y = 310; Val = "axis(2+)"; Texto = "Stick2 Der" }
    }

    $script:cajasUI = @{}

    foreach ($clave in $script:mapeos.Keys) {
        $info = $script:mapeos[$clave]
        
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $info.Label
        $lbl.Location = New-Object System.Drawing.Point($info.X, ($info.Y + 3))
        $lbl.Size = New-Object System.Drawing.Size(95, 20)
        $ctrlForm.Controls.Add($lbl)

        $btnCap = New-Object System.Windows.Forms.Button
        $btnCap.Text = $info.Texto
        $btnCap.Tag = $clave
        $btnCap.Location = New-Object System.Drawing.Point(($info.X + 98), $info.Y)
        $btnCap.Size = New-Object System.Drawing.Size(115, 24)
        $btnCap.BackColor = [System.Drawing.Color]::White
        $btnCap.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnCap.Font = New-Object System.Drawing.Font("Segoe UI", 8)

        $btnCap.Add_Click({
            param($sender, $e)
            foreach ($k in $script:cajasUI.Keys) {
                $script:cajasUI[$k].BackColor = [System.Drawing.Color]::White
            }
            $sender.BackColor = [System.Drawing.Color]::Gold
            $sender.Text = "Presiona..."
            $script:botonEnEspera = $sender
        })

        $ctrlForm.Controls.Add($btnCap)
        $script:cajasUI[$clave] = $btnCap
    }

    $timerMando = New-Object System.Windows.Forms.Timer
    $timerMando.Interval = 50
    $timerMando.Add_Tick({
        if ($script:botonEnEspera -ne $null -and $mandosConectados.Count -gt 0) {
            $idMando = $mandosConectados[0].Id
            $joy = [Win32N64]::LeerMando($idMando)
            if ($joy.dwSize -ne -1) {
                $claveActual = $script:botonEnEspera.Tag
                $detectadoTexto = $null
                $detectadoSDL = $null

                if ($joy.dwYpos -lt 15000) { $detectadoTexto = "Stick Arriba"; $detectadoSDL = "axis(1-)" }
                elseif ($joy.dwYpos -gt 50000) { $detectadoTexto = "Stick Abajo"; $detectadoSDL = "axis(1+)" }
                elseif ($joy.dwXpos -lt 15000) { $detectadoTexto = "Stick Izq"; $detectadoSDL = "axis(0-)" }
                elseif ($joy.dwXpos -gt 50000) { $detectadoTexto = "Stick Der"; $detectadoSDL = "axis(0+)" }
                elseif ($joy.dwRpos -lt 15000) { $detectadoTexto = "Stick2 Arriba"; $detectadoSDL = "axis(3-)" }
                elseif ($joy.dwRpos -gt 50000) { $detectadoTexto = "Stick2 Abajo"; $detectadoSDL = "axis(3+)" }
                elseif ($joy.dwZpos -lt 15000) { $detectadoTexto = "Stick2 Izq"; $detectadoSDL = "axis(2-)" }
                elseif ($joy.dwZpos -gt 50000) { $detectadoTexto = "Stick2 Der"; $detectadoSDL = "axis(2+)" }
                elseif ($joy.dwButtons -gt 0) {
                    for ($b = 0; $b -lt 16; $b++) {
                        if (($joy.dwButtons -band (1 -shl $b)) -ne 0) {
                            $detectadoTexto = "Boton $($b + 1)"
                            $detectadoSDL = "button($b)"
                            break
                        }
                    }
                }

                if ($detectadoTexto) {
                    $script:mapeos[$claveActual].Val = $detectadoSDL
                    $script:mapeos[$claveActual].Texto = $detectadoTexto
                    $script:botonEnEspera.Text = $detectadoTexto
                    $script:botonEnEspera.BackColor = [System.Drawing.Color]::LightGreen
                    $script:botonEnEspera = $null
                }
            }
        }
    })
    $timerMando.Start()

    $ctrlForm.Add_KeyDown({
        param($sender, $e)
        if ($script:botonEnEspera -ne $null) {
            $claveActual = $script:botonEnEspera.Tag
            $nombreTecla = $e.KeyCode.ToString()
            $codigoSDL = [int]$e.KeyValue
            
            $script:mapeos[$claveActual].Val = "key($codigoSDL)"
            $script:mapeos[$claveActual].Texto = "Tecla: $nombreTecla"
            $script:botonEnEspera.Text = "Tecla: $nombreTecla"
            $script:botonEnEspera.BackColor = [System.Drawing.Color]::LightBlue
            $script:botonEnEspera = $null
            $e.Handled = $true
        }
    })

    $ctrlForm.Add_FormClosing({ $timerMando.Stop() })

    $btnGuardar = New-Object System.Windows.Forms.Button
    $btnGuardar.Text = "Guardar y Aplicar al Juego"
    $btnGuardar.Location = New-Object System.Drawing.Point(270, 430)
    $btnGuardar.Size = New-Object System.Drawing.Size(210, 38)
    $btnGuardar.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnGuardar.ForeColor = [System.Drawing.Color]::White
    $btnGuardar.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnGuardar.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)

    $btnGuardar.Add_Click({
        $numJugador = $comboJugador.SelectedIndex + 1
        $seccionCfg = "[Input-SDL-Control$numJugador]"
        $esTeclado = ($comboDisp.SelectedIndex -eq 0)
        $dispositivoId = if ($esTeclado) { "-1" } else { "0" }
        $nombreDispCfg = if ($esTeclado) { '"Keyboard"' } else { "`"$($mandosConectados[0].Nombre)`"" }

        $bloqueConfig = @"
$seccionCfg
version = 2.000000
mode = 0
device = $dispositivoId
name = $nombreDispCfg
plugged = True
plugin = 2
mouse = False
MouseSensitivity = "2.00,2.00"
AnalogDeadzone = "4096,4096"
AnalogPeak = "32768,32768"
DPad R = "key(100)"
DPad L = "key(97)"
DPad D = "key(115)"
DPad U = "key(119)"
Start = "$($script:mapeos["Start"].Val)"
Z Trig = "$($script:mapeos["ZTrig"].Val)"
B Button = "$($script:mapeos["BtnB"].Val)"
A Button = "$($script:mapeos["BtnA"].Val)"
C Button R = "$($script:mapeos["CRight"].Val)"
C Button L = "$($script:mapeos["CLeft"].Val)"
C Button D = "$($script:mapeos["CDown"].Val)"
C Button U = "$($script:mapeos["CUp"].Val)"
R Trig = "$($script:mapeos["RTrig"].Val)"
L Trig = "$($script:mapeos["LTrig"].Val)"
Mempak switch = "key(44)"
Rumblepak switch = "key(46)"
X Axis = "axis(0-),axis(0+)"
Y Axis = "axis(1-),axis(1+)"
"@

        if (!(Test-Path $rutaConfigLocal)) { New-Item -ItemType Directory -Path $rutaConfigLocal | Out-Null }
        $archivoCfg = Join-Path $rutaConfigLocal "mupen64plus.cfg"

        if (Test-Path $archivoCfg) {
            $contenido = Get-Content $archivoCfg -Raw
            $patron = "(?s)\[Input-SDL-Control$numJugador\].*?(?=\r?\n\[|\z)"
            if ($contenido -match $patron) {
                $contenido = [regex]::Replace($contenido, $patron, $bloqueConfig)
            } else {
                $contenido += "`r`n`r`n$bloqueConfig"
            }
            Set-Content -Path $archivoCfg -Value $contenido -Encoding ASCII
        } else {
            Set-Content -Path $archivoCfg -Value $bloqueConfig -Encoding ASCII
        }

        [System.Windows.Forms.MessageBox]::Show("Configuracion de mandos y ejes completos guardada para el Jugador $numJugador.", "Console64", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $ctrlForm.Close()
    })
    $ctrlForm.Controls.Add($btnGuardar)

    [void]$ctrlForm.ShowDialog()
})

# ==============================================================================
# 7. LANZAR JUEGO (MODO ULTRARRÁPIDO Y LIMPIO)
# ==============================================================================
function Lanzar-Juego {
    param([string]$rutaRom, [string]$nombreJuego)
    
    $emulador = Get-ChildItem -Path $rutaCore -Filter "mupen64plus-ui-console.exe" -Recurse | Select-Object -First 1
    if (-not $emulador) {
        $emulador = Get-ChildItem -Path $rutaCore -Filter "*.exe" -Recurse | Select-Object -First 1
    }
    
    if ($emulador) {
        $statusLabel.Text = "Ejecutando (Modo Ultra Rápido): $nombreJuego..."
        
        $argumentos = "`"$rutaRom`""
        if (Test-Path (Join-Path $rutaConfigLocal "mupen64plus.cfg")) {
            $argumentos = "--configdir `"$rutaConfigLocal`" `"$rutaRom`""
        }

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $emulador.FullName
        $startInfo.Arguments = $argumentos
        $startInfo.WorkingDirectory = $emulador.DirectoryName
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        $proc = [System.Diagnostics.Process]::Start($startInfo)

        Start-Job -ScriptBlock {
            param($idProc, $nuevoTitulo)
            Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            public class Win32Title {
                [DllImport("user32.dll")]
                public static extern bool SetWindowText(IntPtr hwnd, String lpString);
            }
"@
            $intentos = 0
            while ($intentos -lt 30) {
                Start-Sleep -Milliseconds 400
                $p = Get-Process -Id $idProc -ErrorAction SilentlyContinue
                if ($p -and $p.MainWindowHandle -ne 0) {
                    [Win32Title]::SetWindowText($p.MainWindowHandle, $nuevoTitulo)
                    break
                }
                $intentos++
            }
        } -ArgumentList $proc.Id, "Console64 - $nombreJuego" | Out-Null

    } else {
        [System.Windows.Forms.MessageBox]::Show("No se encontro el motor en almacen\Core.", "Console64", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}

# Eventos de menus
$itemRefrescar.Add_Click({ Cargar-Biblioteca })
$itemCarpetaRoms.Add_Click({ Start-Process explorer $rutaRoms })
$itemCarpetaCore.Add_Click({ Start-Process explorer $rutaCore })

$itemAbrir.Add_Click({
    $dialogo = New-Object System.Windows.Forms.OpenFileDialog
    $dialogo.Filter = "ROMs de N64 (*.z64;*.n64;*.v64)|*.z64;*.n64;*.v64"
    if ($dialogo.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Lanzar-Juego -rutaRom $dialogo.FileName -nombreJuego [System.IO.Path]::GetFileNameWithoutExtension($dialogo.FileName)
    }
})

$listView.Add_DoubleClick({
    if ($listView.SelectedItems.Count -gt 0) {
        $seleccion = $listView.SelectedItems[0]
        Lanzar-Juego -rutaRom $seleccion.Tag -nombreJuego $seleccion.Text
    }
})

Cargar-Biblioteca
[void]$form.ShowDialog()