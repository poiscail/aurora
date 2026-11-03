# Aurora - tableau de bord élégant pour Windows 10 / 11 (WPF natif, aucune installation)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Appels Windows directs : ~1000x plus rapides que WMI (qui bloquait l'interface ~1 s par relevé)
Add-Type -Namespace Aurora -Name Native -MemberDefinition @'
[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr h, int attr, ref int val, int size);
[DllImport("kernel32.dll")] public static extern bool GetSystemTimes(out long idle, out long kernel, out long user);
[DllImport("kernel32.dll")] public static extern ulong GetTickCount64();
[StructLayout(LayoutKind.Sequential)] public struct MEM { public uint len, load; public ulong total, avail, tpf, apf, tv, av, ave; }
[DllImport("kernel32.dll")] public static extern bool GlobalMemoryStatusEx(ref MEM m);
'@

# Mica (fond vitré géré par Windows, quasi gratuit) : Windows 11 22H2+ uniquement
$build = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
$mica = $build -ge 22621

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Aurora" Width="900" Height="560" WindowStartupLocation="CenterScreen"
        WindowStyle="None" ResizeMode="CanMinimize" Background="#0F1028"
        FontFamily="Segoe UI Variable Display, Segoe UI" UseLayoutRounding="True"
        TextOptions.TextFormattingMode="Display">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="44" GlassFrameThickness="-1" ResizeBorderThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <LinearGradientBrush x:Key="Accent" StartPoint="0,0" EndPoint="1,1">
      <GradientStop Color="#7CF7E4" Offset="0"/><GradientStop Color="#9AA8FF" Offset="0.5"/><GradientStop Color="#C77CFF" Offset="1"/>
    </LinearGradientBrush>
    <Style x:Key="Caption" TargetType="Button">
      <Setter Property="Width" Value="46"/><Setter Property="Height" Value="32"/>
      <Setter Property="Foreground" Value="#CCFFFFFF"/><Setter Property="FontSize" Value="10"/>
      <Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="Transparent" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Tile" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="6"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" CornerRadius="16" Background="#14FFFFFF" BorderBrush="#1FFFFFFF" BorderThickness="1" RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform><ScaleTransform x:Name="s"/></Border.RenderTransform>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#26FFFFFF"/>
                <Setter TargetName="b" Property="BorderBrush" Value="{StaticResource Accent}"/>
                <Trigger.EnterActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleX" To="1.04" Duration="0:0:0.12"/>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleY" To="1.04" Duration="0:0:0.12"/>
                </Storyboard></BeginStoryboard></Trigger.EnterActions>
                <Trigger.ExitActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.12"/>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.12"/>
                </Storyboard></BeginStoryboard></Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Background" Value="#0DFFFFFF"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Icon" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="FontSize" Value="24"/><Setter Property="HorizontalAlignment" Value="Center"/>
      <Setter Property="Foreground" Value="{StaticResource Accent}"/>
    </Style>
    <Style x:Key="TileText" TargetType="TextBlock">
      <Setter Property="Margin" Value="0,10,0,0"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="Foreground" Value="#E6FFFFFF"/>
    </Style>
    <Style x:Key="Track" TargetType="Ellipse">
      <Setter Property="Stroke" Value="#1AFFFFFF"/><Setter Property="StrokeThickness" Value="8"/><Setter Property="Margin" Value="4"/>
    </Style>
    <Style x:Key="Arc" TargetType="Path">
      <Setter Property="Stroke" Value="{StaticResource Accent}"/><Setter Property="StrokeThickness" Value="8"/>
      <Setter Property="StrokeStartLineCap" Value="Round"/><Setter Property="StrokeEndLineCap" Value="Round"/>
    </Style>
    <Style x:Key="Pct" TargetType="TextBlock">
      <Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="20"/><Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
    <Style x:Key="Label" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#E6FFFFFF"/><Setter Property="FontSize" Value="13"/><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="Margin" Value="0,10,0,0"/>
    </Style>
    <Style x:Key="Sub" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#80FFFFFF"/><Setter Property="FontSize" Value="11"/><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="Margin" Value="0,2,0,0"/>
    </Style>
  </Window.Resources>

  <Grid x:Name="Root" Opacity="0">
    <Grid.RenderTransform><TranslateTransform x:Name="Slide" Y="14"/></Grid.RenderTransform>
    <!-- teinte posée sur le Mica (opaque sous Windows 10) -->
    <Rectangle>
      <Rectangle.Fill>
        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
          <GradientStop x:Name="Tint0" Color="#D90F1028" Offset="0"/>
          <GradientStop x:Name="Tint1" Color="#D91E1446" Offset="0.55"/>
          <GradientStop x:Name="Tint2" Color="#D90B2A3A" Offset="1"/>
        </LinearGradientBrush>
      </Rectangle.Fill>
    </Rectangle>
    <Ellipse x:Name="Glow1" Width="460" Height="460" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-150,-190,0,0" Opacity="0.4" IsHitTestVisible="False">
      <Ellipse.Fill><RadialGradientBrush><GradientStop Color="#B57CFF" Offset="0"/><GradientStop Color="#00B57CFF" Offset="1"/></RadialGradientBrush></Ellipse.Fill>
    </Ellipse>
    <Ellipse x:Name="Glow2" Width="520" Height="520" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-170,-240" Opacity="0.35" IsHitTestVisible="False">
      <Ellipse.Fill><RadialGradientBrush><GradientStop Color="#3EE6C8" Offset="0"/><GradientStop Color="#003EE6C8" Offset="1"/></RadialGradientBrush></Ellipse.Fill>
    </Ellipse>

    <Grid Margin="36,6,24,32">
      <Grid.RowDefinitions><RowDefinition Height="38"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>

      <DockPanel>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock Text="✦" Foreground="{StaticResource Accent}" FontSize="14" Margin="0,0,8,0"/>
          <TextBlock Text="AURORA" Foreground="#99FFFFFF" FontSize="11" FontWeight="SemiBold" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
          <Button x:Name="BtnMin" Style="{StaticResource Caption}" Content="&#xE921;" Tag="#1AFFFFFF"/>
          <Button x:Name="BtnClose" Style="{StaticResource Caption}" Content="&#xE8BB;" Tag="#E81123"/>
        </StackPanel>
      </DockPanel>

      <DockPanel Grid.Row="1" Margin="0,8,12,22" LastChildFill="False">
        <StackPanel>
          <TextBlock x:Name="Greeting" Foreground="#CCFFFFFF" FontSize="18"/>
          <TextBlock x:Name="Clock" FontSize="76" FontWeight="Light" Foreground="White" Margin="-3,-6,0,-6"/>
          <TextBlock x:Name="DateTxt" Foreground="#8CFFFFFF" FontSize="15"/>
        </StackPanel>
        <StackPanel DockPanel.Dock="Right" VerticalAlignment="Bottom">
          <TextBlock Text="EN MARCHE DEPUIS" Foreground="#66FFFFFF" FontSize="10" FontWeight="SemiBold" HorizontalAlignment="Right"/>
          <TextBlock x:Name="UptimeTxt" Foreground="#E6FFFFFF" FontSize="15" HorizontalAlignment="Right" Margin="0,2,0,0"/>
        </StackPanel>
      </DockPanel>

      <Grid Grid.Row="2" Margin="0,0,12,0">
        <Grid.ColumnDefinitions><ColumnDefinition Width="1.15*"/><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

        <Border CornerRadius="20" Background="#12FFFFFF" BorderBrush="#1AFFFFFF" BorderThickness="1" Padding="18,22">
          <UniformGrid Columns="3" VerticalAlignment="Center">
            <StackPanel>
              <Grid Width="96" Height="96"><Ellipse Style="{StaticResource Track}"/><Path x:Name="CpuArc" Style="{StaticResource Arc}"/><TextBlock x:Name="CpuPct" Style="{StaticResource Pct}"/></Grid>
              <TextBlock Text="Processeur" Style="{StaticResource Label}"/><TextBlock x:Name="CpuSub" Style="{StaticResource Sub}"/>
            </StackPanel>
            <StackPanel>
              <Grid Width="96" Height="96"><Ellipse Style="{StaticResource Track}"/><Path x:Name="RamArc" Style="{StaticResource Arc}"/><TextBlock x:Name="RamPct" Style="{StaticResource Pct}"/></Grid>
              <TextBlock Text="Mémoire" Style="{StaticResource Label}"/><TextBlock x:Name="RamSub" Style="{StaticResource Sub}"/>
            </StackPanel>
            <StackPanel>
              <Grid Width="96" Height="96"><Ellipse Style="{StaticResource Track}"/><Path x:Name="DiskArc" Style="{StaticResource Arc}"/><TextBlock x:Name="DiskPct" Style="{StaticResource Pct}"/></Grid>
              <TextBlock x:Name="DiskLabel" Style="{StaticResource Label}"/><TextBlock x:Name="DiskSub" Style="{StaticResource Sub}"/>
            </StackPanel>
          </UniformGrid>
        </Border>

        <UniformGrid Grid.Column="2" Rows="2" Columns="3" Margin="-6">
          <Button Style="{StaticResource Tile}" Tag="explorer.exe"><StackPanel><TextBlock Style="{StaticResource Icon}" Text="&#xE8B7;"/><TextBlock Style="{StaticResource TileText}" Text="Fichiers"/></StackPanel></Button>
          <Button Style="{StaticResource Tile}" Tag="ms-settings:"><StackPanel><TextBlock Style="{StaticResource Icon}" Text="&#xE713;"/><TextBlock Style="{StaticResource TileText}" Text="Paramètres"/></StackPanel></Button>
          <Button Style="{StaticResource Tile}" Tag="taskmgr.exe"><StackPanel><TextBlock Style="{StaticResource Icon}" Text="&#xE9D9;"/><TextBlock Style="{StaticResource TileText}" Text="Tâches"/></StackPanel></Button>
          <Button Style="{StaticResource Tile}" Tag="powershell.exe"><StackPanel><TextBlock Style="{StaticResource Icon}" Text="&#xE756;"/><TextBlock Style="{StaticResource TileText}" Text="Terminal"/></StackPanel></Button>
          <Button Style="{StaticResource Tile}" Tag="calc.exe"><StackPanel><TextBlock Style="{StaticResource Icon}" Text="&#xE8EF;"/><TextBlock Style="{StaticResource TileText}" Text="Calcul"/></StackPanel></Button>
          <Button Style="{StaticResource Tile}" Tag="https://github.com"><StackPanel><TextBlock Style="{StaticResource Icon}" Text="&#xE774;"/><TextBlock Style="{StaticResource TileText}" Text="Web"/></StackPanel></Button>
        </UniformGrid>
      </Grid>
    </Grid>
  </Grid>
</Window>
'@

$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
$xaml.SelectNodes('//*[@*[local-name()="Name"]]') | ForEach-Object { $n = $_.Attributes['x:Name'].Value; $ui[$n] = $win.FindName($n) }

$ui.BtnClose.Add_Click({ $win.Close() })
$ui.BtnMin.Add_Click({ $win.WindowState = 'Minimized' })

# Les tuiles lancent leur Tag (programme, dossier ou URL)
$win.AddHandler([Windows.Controls.Button]::ClickEvent, [Windows.RoutedEventHandler]{
    param($s, $e)
    $b = $e.OriginalSource
    if ($b.Style -ne $win.FindResource('Tile')) { return }
    try { Start-Process $b.Tag } catch { [Windows.MessageBox]::Show("Impossible d'ouvrir $($b.Tag)", 'Aurora') | Out-Null }
})

$win.Add_SourceInitialized({
    $h = (New-Object Windows.Interop.WindowInteropHelper $win).Handle
    $v = 1; [void][Aurora.Native]::DwmSetWindowAttribute($h, 20, [ref]$v, 4)      # barre sombre
    $v = 2; [void][Aurora.Native]::DwmSetWindowAttribute($h, 33, [ref]$v, 4)      # coins arrondis (Win 11)
    if ($mica) {
        $win.Background = [Windows.Media.Brushes]::Transparent
        [Windows.Interop.HwndSource]::FromHwnd($h).CompositionTarget.BackgroundColor = [Windows.Media.Colors]::Transparent
        $v = 2; [void][Aurora.Native]::DwmSetWindowAttribute($h, 38, [ref]$v, 4)  # Mica
    } else {
        foreach ($t in 'Tint0', 'Tint1', 'Tint2') { $c = $ui[$t].Color; $c.A = 255; $ui[$t].Color = $c }
    }
})

# Apparition en fondu (une seule fois)
$win.Add_ContentRendered({
    $ease = New-Object Windows.Media.Animation.CubicEase
    $fade = New-Object Windows.Media.Animation.DoubleAnimation(1, [TimeSpan]::FromMilliseconds(450)); $fade.EasingFunction = $ease
    $up = New-Object Windows.Media.Animation.DoubleAnimation(0, [TimeSpan]::FromMilliseconds(450)); $up.EasingFunction = $ease
    $ui.Root.BeginAnimation([Windows.UIElement]::OpacityProperty, $fade)
    $ui.Slide.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, $up)
})

$inv = [Globalization.CultureInfo]::InvariantCulture
function Set-Arc($path, [double]$v) {
    $v = [Math]::Min([Math]::Max($v, 0), 99.9)
    $a = $v * [Math]::PI / 50
    $path.Data = [Windows.Media.Geometry]::Parse([string]::Format($inv, 'M48,8 A40,40 0 {0} 1 {1:F2},{2:F2}',
        [int]($v -gt 50), (48 + 40 * [Math]::Sin($a)), (48 - 40 * [Math]::Cos($a))))
}

$fr = [Globalization.CultureInfo]'fr-FR'
$drive = New-Object IO.DriveInfo $env:SystemDrive
$ui.DiskLabel.Text = "Disque $env:SystemDrive"
$ui.CpuSub.Text = "$([Environment]::ProcessorCount) threads"
$idle = 0L; $kern = 0L; $user = 0L
[void][Aurora.Native]::GetSystemTimes([ref]$idle, [ref]$kern, [ref]$user)
$script:lastCpu = $idle, $kern, $user   # 1er relevé : l'anneau CPU est rempli dès l'ouverture
$script:tick = 0

function Update-All {
    $now = Get-Date
    $ui.Clock.Text = $now.ToString('HH:mm')
    $ui.DateTxt.Text = $fr.TextInfo.ToTitleCase($now.ToString('dddd d MMMM yyyy', $fr))
    $ui.Greeting.Text = $(if ($now.Hour -ge 5 -and $now.Hour -lt 18) { 'Bonjour' } else { 'Bonsoir' }) + ", $env:USERNAME"

    $idle = 0L; $kern = 0L; $user = 0L
    [void][Aurora.Native]::GetSystemTimes([ref]$idle, [ref]$kern, [ref]$user)
    $total = ($kern - $script:lastCpu[1]) + ($user - $script:lastCpu[2])
    $cpu = if ($total -gt 0) { 100 * (1 - ($idle - $script:lastCpu[0]) / $total) } else { 0 }
    Set-Arc $ui.CpuArc $cpu; $ui.CpuPct.Text = '{0:N0}%' -f $cpu
    $script:lastCpu = $idle, $kern, $user

    $m = New-Object Aurora.Native+MEM; $m.len = 64
    [void][Aurora.Native]::GlobalMemoryStatusEx([ref]$m)
    Set-Arc $ui.RamArc $m.load; $ui.RamPct.Text = "$($m.load)%"
    $ui.RamSub.Text = '{0:N1} / {1:N0} Go' -f (($m.total - $m.avail) / 1GB), ($m.total / 1GB)

    # disque et durée d'allumage bougent lentement : toutes les 30 s suffit
    if ($script:tick++ % 15 -eq 0) {
        $used = 100 * (1 - $drive.TotalFreeSpace / $drive.TotalSize)
        Set-Arc $ui.DiskArc $used; $ui.DiskPct.Text = '{0:N0}%' -f $used
        $ui.DiskSub.Text = '{0:N0} Go libres' -f ($drive.TotalFreeSpace / 1GB)
        $up = [TimeSpan]::FromMilliseconds([Aurora.Native]::GetTickCount64())
        $ui.UptimeTxt.Text = if ($up.Days) { '{0} j {1} h' -f $up.Days, $up.Hours } else { '{0} h {1:D2} min' -f $up.Hours, $up.Minutes }
    }
}

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(2)
$timer.Add_Tick({ Update-All })

# Réduite = plus rien ne tourne
$win.Add_StateChanged({
    if ($win.WindowState -eq 'Minimized') { $timer.Stop() } else { Update-All; $timer.Start() }
})

$win.Add_ContentRendered({ Update-All })  # après ~0,5 s de chargement : vrai % CPU dès l'affichage
$timer.Start()
$win.ShowDialog() | Out-Null
