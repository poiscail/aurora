# Aurora - tableau de bord élégant pour Windows 10 / 11 (WPF natif, aucune installation)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Aurora" Width="880" Height="560" WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" ResizeMode="NoResize"
        FontFamily="Segoe UI Variable Display, Segoe UI">
  <Window.Resources>
    <Style x:Key="Tile" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="6"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" CornerRadius="14" Background="#1AFFFFFF" BorderBrush="#26FFFFFF" BorderThickness="1" Padding="14">
              <Border.RenderTransform><ScaleTransform x:Name="s" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
              <Border.RenderTransformOrigin>0.5,0.5</Border.RenderTransformOrigin>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#33FFFFFF"/>
                <Setter TargetName="b" Property="BorderBrush" Value="#66FFFFFF"/>
                <Trigger.EnterActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleX" To="1.05" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleY" To="1.05" Duration="0:0:0.15"/>
                </Storyboard></BeginStoryboard></Trigger.EnterActions>
                <Trigger.ExitActions><BeginStoryboard><Storyboard>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.15"/>
                  <DoubleAnimation Storyboard.TargetName="s" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.15"/>
                </Storyboard></BeginStoryboard></Trigger.ExitActions>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Bar" TargetType="ProgressBar">
      <Setter Property="Height" Value="8"/>
      <Setter Property="Maximum" Value="100"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ProgressBar">
            <Grid>
              <Border CornerRadius="4" Background="#22FFFFFF"/>
              <Border x:Name="PART_Track"/>
              <Border x:Name="PART_Indicator" CornerRadius="4" HorizontalAlignment="Left">
                <Border.Background>
                  <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#7CF7E4" Offset="0"/><GradientStop Color="#B57CFF" Offset="1"/>
                  </LinearGradientBrush>
                </Border.Background>
              </Border>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border x:Name="Root" CornerRadius="22" Margin="16" ClipToBounds="True">
    <Border.Effect><DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.55"/></Border.Effect>
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#0F1028" Offset="0"/>
        <GradientStop Color="#1E1446" Offset="0.5"/>
        <GradientStop Color="#0B2A3A" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Grid>
      <!-- halos "aurore" animés -->
      <Ellipse x:Name="Glow1" Width="420" Height="420" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-120,-160,0,0" Opacity="0.45">
        <Ellipse.Fill><RadialGradientBrush><GradientStop Color="#B57CFF" Offset="0"/><GradientStop Color="#00B57CFF" Offset="1"/></RadialGradientBrush></Ellipse.Fill>
      </Ellipse>
      <Ellipse x:Name="Glow2" Width="460" Height="460" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-140,-200" Opacity="0.4">
        <Ellipse.Fill><RadialGradientBrush><GradientStop Color="#3EE6C8" Offset="0"/><GradientStop Color="#003EE6C8" Offset="1"/></RadialGradientBrush></Ellipse.Fill>
      </Ellipse>

      <Grid Margin="32,20,32,28">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>

        <!-- barre de titre -->
        <Grid x:Name="TitleBar" Background="Transparent" Height="32">
          <TextBlock Text="✦  AURORA" Foreground="#AAFFFFFF" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="BtnMin" Content="—" Width="32" Foreground="#CCFFFFFF" Background="Transparent" BorderThickness="0" Cursor="Hand"/>
            <Button x:Name="BtnClose" Content="✕" Width="32" Foreground="#CCFFFFFF" Background="Transparent" BorderThickness="0" Cursor="Hand"/>
          </StackPanel>
        </Grid>

        <!-- horloge -->
        <StackPanel Grid.Row="1" Margin="0,14,0,18">
          <TextBlock x:Name="Greeting" Foreground="#CCFFFFFF" FontSize="18"/>
          <TextBlock x:Name="Clock" Foreground="White" FontSize="72" FontWeight="Light"/>
          <TextBlock x:Name="DateTxt" Foreground="#99FFFFFF" FontSize="16"/>
        </StackPanel>

        <Grid Grid.Row="2">
          <Grid.ColumnDefinitions><ColumnDefinition Width="1.1*"/><ColumnDefinition Width="24"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

          <!-- système -->
          <Border CornerRadius="18" Background="#14FFFFFF" BorderBrush="#22FFFFFF" BorderThickness="1" Padding="22">
            <StackPanel>
              <TextBlock Text="Système" Foreground="White" FontSize="16" FontWeight="SemiBold" Margin="0,0,0,14"/>
              <DockPanel><TextBlock Text="Processeur" Foreground="#BBFFFFFF"/><TextBlock x:Name="CpuTxt" Foreground="White" HorizontalAlignment="Right"/></DockPanel>
              <ProgressBar x:Name="CpuBar" Style="{StaticResource Bar}" Margin="0,6,0,16"/>
              <DockPanel><TextBlock Text="Mémoire" Foreground="#BBFFFFFF"/><TextBlock x:Name="RamTxt" Foreground="White" HorizontalAlignment="Right"/></DockPanel>
              <ProgressBar x:Name="RamBar" Style="{StaticResource Bar}" Margin="0,6,0,16"/>
              <DockPanel><TextBlock Text="Disque C:" Foreground="#BBFFFFFF"/><TextBlock x:Name="DiskTxt" Foreground="White" HorizontalAlignment="Right"/></DockPanel>
              <ProgressBar x:Name="DiskBar" Style="{StaticResource Bar}" Margin="0,6,0,0"/>
            </StackPanel>
          </Border>

          <!-- raccourcis -->
          <UniformGrid Grid.Column="2" Rows="2" Columns="3">
            <Button Style="{StaticResource Tile}" Tag="explorer.exe"><StackPanel><TextBlock Text="📁" FontSize="26" HorizontalAlignment="Center"/><TextBlock Text="Fichiers" Margin="0,6,0,0" HorizontalAlignment="Center"/></StackPanel></Button>
            <Button Style="{StaticResource Tile}" Tag="ms-settings:"><StackPanel><TextBlock Text="⚙️" FontSize="26" HorizontalAlignment="Center"/><TextBlock Text="Paramètres" Margin="0,6,0,0" HorizontalAlignment="Center"/></StackPanel></Button>
            <Button Style="{StaticResource Tile}" Tag="taskmgr.exe"><StackPanel><TextBlock Text="📊" FontSize="26" HorizontalAlignment="Center"/><TextBlock Text="Tâches" Margin="0,6,0,0" HorizontalAlignment="Center"/></StackPanel></Button>
            <Button Style="{StaticResource Tile}" Tag="powershell.exe"><StackPanel><TextBlock Text="⌨️" FontSize="26" HorizontalAlignment="Center"/><TextBlock Text="Terminal" Margin="0,6,0,0" HorizontalAlignment="Center"/></StackPanel></Button>
            <Button Style="{StaticResource Tile}" Tag="calc.exe"><StackPanel><TextBlock Text="🧮" FontSize="26" HorizontalAlignment="Center"/><TextBlock Text="Calcul" Margin="0,6,0,0" HorizontalAlignment="Center"/></StackPanel></Button>
            <Button Style="{StaticResource Tile}" Tag="https://github.com"><StackPanel><TextBlock Text="🌐" FontSize="26" HorizontalAlignment="Center"/><TextBlock Text="Web" Margin="0,6,0,0" HorizontalAlignment="Center"/></StackPanel></Button>
          </UniformGrid>
        </Grid>
      </Grid>
    </Grid>
  </Border>
</Window>
'@

$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
$xaml.SelectNodes('//*[@*[local-name()="Name"]]') | ForEach-Object { $n = $_.Attributes['x:Name'].Value; $ui[$n] = $win.FindName($n) }

$ui.TitleBar.Add_MouseLeftButtonDown({ $win.DragMove() })
$ui.BtnClose.Add_Click({ $win.Close() })
$ui.BtnMin.Add_Click({ $win.WindowState = 'Minimized' })

# Tous les boutons tuiles lancent leur Tag
$win.AddHandler([Windows.Controls.Button]::ClickEvent, [Windows.RoutedEventHandler]{
    param($s, $e)
    $t = $e.OriginalSource.Tag
    if ($t) { try { Start-Process $t } catch { [Windows.MessageBox]::Show("Impossible d'ouvrir $t", 'Aurora') | Out-Null } }
})

# Halos qui respirent
foreach ($g in 'Glow1', 'Glow2') {
    $a = New-Object Windows.Media.Animation.DoubleAnimation(0.2, 0.55, [TimeSpan]::FromSeconds(4))
    $a.AutoReverse = $true; $a.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever
    $ui[$g].BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
}

$fr = [Globalization.CultureInfo]'fr-FR'
function Update-Clock {
    $now = Get-Date
    $ui.Clock.Text = $now.ToString('HH:mm')
    $ui.DateTxt.Text = $fr.TextInfo.ToTitleCase($now.ToString('dddd d MMMM yyyy', $fr))
    $ui.Greeting.Text = if ($now.Hour -lt 6 -or $now.Hour -ge 18) { "Bonsoir, $env:USERNAME" } else { "Bonjour, $env:USERNAME" }
}
function Update-Stats {
    $cpu = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
    $os = Get-CimInstance Win32_OperatingSystem
    $ram = 100 * (1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize)
    $c = Get-PSDrive C
    $disk = 100 * $c.Used / ($c.Used + $c.Free)
    $ui.CpuBar.Value = $cpu;  $ui.CpuTxt.Text = '{0:N0} %' -f $cpu
    $ui.RamBar.Value = $ram;  $ui.RamTxt.Text = '{0:N1} / {1:N1} Go' -f (($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB), ($os.TotalVisibleMemorySize / 1MB)
    $ui.DiskBar.Value = $disk; $ui.DiskTxt.Text = '{0:N0} Go libres' -f ($c.Free / 1GB)
}

Update-Clock; Update-Stats
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(2)
$timer.Add_Tick({ Update-Clock; Update-Stats })
$timer.Start()

$win.ShowDialog() | Out-Null
