# Starting Program
Write-Output "Starting ProgramZelva ToolBox..."

Add-Type -AssemblyName PresentationFramework

# ---------- XAML ----------
[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='ProgramZelva ToolBox pre-release 1.0'
        Height='600' Width='1000'
        ResizeMode='CanResize'
        MinWidth='1000' MinHeight='600'
        Background='White'>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height='Auto'/>
            <RowDefinition Height='*'/>
            <RowDefinition Height='Auto'/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width='200'/>
            <ColumnDefinition Width='*'/>
        </Grid.ColumnDefinitions>

        <ListBox x:Name='CategoryList'
                 Grid.Row='1' Grid.Column='0'
                 Margin='10'
                 Background='#f5f5f5'>
            <ListBoxItem Content='Browsers'/>
            <ListBoxItem Content='Communications'/>
            <ListBoxItem Content='Multimedia'/>
            <ListBoxItem Content='Utilities'/>
            <ListBoxItem Content='Productivity'/>
        </ListBox>

        <ScrollViewer Grid.Row='1' Grid.Column='1' Margin='10'>
            <StackPanel x:Name='AppList'/>
        </ScrollViewer>

        <StackPanel Grid.Row='2' Grid.ColumnSpan='2'
                    Orientation='Horizontal'
                    HorizontalAlignment='Center'
                    Margin='10'>
            <Button x:Name='InstallButton' Content='Install Selected'
                    Width='150' Height='40' Margin='10'
                    Background='#007ACC' Foreground='White'/>
            <Button x:Name='UninstallButton' Content='Uninstall Selected'
                    Width='150' Height='40' Margin='10'
                    Background='#FF5733' Foreground='White'/>
            <Button x:Name='VersionButton' Content='Version info'
                    Width='150' Height='40' Margin='10'
                    Background='#32CD32' Foreground='White'/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# ---------- JSON ----------
$url = "https://raw.githubusercontent.com/ProgramZelva-dev/ProgramZelva-ToolBox/main/applications.json"
$jsonData = Invoke-RestMethod -Uri $url

# ---------- Mapování UI → JSON ----------
$CategoryMap = @{
    "Browsers"       = "Browsers"
    "Communications" = "Communications"
    "Multimedia"     = "MultimediaTools"
    "Utilities"      = "Utilities"
    "Productivity"   = "Productivity"
}

# ---------- Funkce ----------
function ShowApplications ($uiCategory) {
    $jsonKey = $CategoryMap[$uiCategory]
    $appList = $window.FindName("AppList")
    $appList.Children.Clear()

    foreach ($app in $jsonData.$jsonKey) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $app.Name
        $cb.Tag = $app.WingetID
        $cb.Margin = "5"
        $appList.Children.Add($cb)
    }
}

function RunWinget ($args) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        [System.Windows.MessageBox]::Show("Winget není dostupný.","Chyba")
        return
    }
    Start-Process winget -ArgumentList $args -NoNewWindow
}

function InstallSelectedApps {
    foreach ($c in $window.FindName("AppList").Children) {
        if ($c.IsChecked) {
            RunWinget "install --id $($c.Tag) --scope user -e"
        }
    }
}

function UninstallSelectedApps {
    foreach ($c in $window.FindName("AppList").Children) {
        if ($c.IsChecked) {
            RunWinget "uninstall --id $($c.Tag) -e"
        }
    }
}

function ShowVersionInfo {
    foreach ($c in $window.FindName("AppList").Children) {
        if ($c.IsChecked) {
            RunWinget "show --id $($c.Tag)"
        }
    }
}

# ---------- Events ----------
$window.FindName("CategoryList").Add_SelectionChanged({
    if ($_.AddedItems.Count -gt 0) {
        ShowApplications $_.AddedItems[0].Content
    }
})

$window.FindName("InstallButton").Add_Click({ InstallSelectedApps })
$window.FindName("UninstallButton").Add_Click({ UninstallSelectedApps })
$window.FindName("VersionButton").Add_Click({ ShowVersionInfo })

# Default
ShowApplications "Browsers"
$window.ShowDialog() | Out-Null
