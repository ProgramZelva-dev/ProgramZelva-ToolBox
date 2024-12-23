Write-Output "Starting ProgramZelva ToolBox..."

# Nacteni WPF
Add-Type -AssemblyName PresentationFramework

# Vytvoreni okna
[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' 
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='ProgramZelva ToolBox pre-release 1.0' Height='600' Width='1000' 
        ResizeMode='CanResize' MinWidth='1000' MinHeight='600'
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

        <!-- Kategorie vlevo -->
        <ListBox x:Name='CategoryList' Grid.Row='1' Grid.Column='0' Background='#f5f5f5' Foreground='Black' 
                 Margin='10'>
            <ListBoxItem Content='Browsers' Foreground='Black'/>
            <ListBoxItem Content='Communications' Foreground='Black'/>
            <ListBoxItem Content='MultimediaTools' Foreground='Black'/>
            <ListBoxItem Content='Utilities' Foreground='Black'/>
            <ListBoxItem Content='Productivity' Foreground='Black'/>
        </ListBox>

        <!-- Aplikace vpravo -->
        <ScrollViewer Grid.Row='1' Grid.Column='1' Margin='10' Background='Transparent'>
            <StackPanel x:Name='AppList'>
                <!-- Naplni se programy -->
            </StackPanel>
        </ScrollViewer>

        <!-- Tlacitka -->
        <StackPanel Grid.Row='2' Grid.ColumnSpan='2' Orientation='Horizontal' HorizontalAlignment='Center' Margin='10'>
            <Button Content='Install Selected' Width='150' Height='40' Margin='10' 
                    Background='#007ACC' Foreground='White' x:Name='InstallButton'/>
            <Button Content='Uninstall Selected' Width='150' Height='40' Margin='10' 
                    Background='#FF5733' Foreground='White' x:Name='UninstallButton'/>
            <Button Content='Version info' Width='150' Height='40' Margin='10' 
                    Background='#32CD32' Foreground='White' x:Name='VersionButton'/>
        </StackPanel>
    </Grid>
</Window>
"@

# Nacteni XAML a vytvoreni GUI
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
    Write-Output "Okno uspesne nacteno."
} catch {
    Write-Error "Nepodarilo se nacist okno z XAML: $_"
    return
}

# Definice aplikaci primo v kodu
$applications = @{
    Browsers = @(
        @{ Name = "Firefox"; WingetID = "Mozilla.Firefox" },
        @{ Name = "Google Chrome"; WingetID = "Google.Chrome" }
    )
    Communications = @(
        @{ Name = "Discord"; WingetID = "Discord.Discord" }
    )
    MultimediaTools = @(
        @{ Name = "Audacity"; WingetID = "Audacity.Audacity" }
    )
    Utilities = @(
        @{ Name = "7-Zip"; WingetID = "7zip.7zip" }
    )
    Productivity = @(
        @{ Name = "Microsoft Office"; WingetID = "Microsoft.Office" }
    )
}

# Funkce pro zobrazeni aplikaci podle kategorie
function ShowApplications($category) {
    $appList = $window.FindName("AppList")
    if ($appList -eq $null) {
        Write-Error "AppList nebyl nalezen."
        return
    }
    $appList.Children.Clear()

    if ($applications.ContainsKey($category)) {
        $categoryApplications = $applications[$category]
        foreach ($app in $categoryApplications) {
            $checkBox = New-Object System.Windows.Controls.CheckBox
            $checkBox.Content = $app.Name
            $checkBox.Tag = $app.WingetID
            $checkBox.Foreground = [System.Windows.Media.Brushes]::Black
            $appList.Children.Add($checkBox)
        }
        Write-Output "Aplikace uspesne nacteny pro kategorii: $category"
    } else {
        Write-Output "Kategorie '$category' neexistuje."
    }
}

# Inicialni zobrazeni kategorii
ShowApplications "Browsers"

# Udalosti pro kategorie
$categoryList = $window.FindName("CategoryList")
$categoryList.add_SelectionChanged({
    $selectedCategory = $categoryList.SelectedItem.Content
    ShowApplications $selectedCategory
})

# Tlacitka pro instalaci a odinstalaci
$installButton = $window.FindName("InstallButton")
$installButton.Add_Click({
    Write-Output "Instalace aplikaci..."
    $appList = $window.FindName("AppList")
    foreach ($child in $appList.Children) {
        if ($child.IsChecked -eq $true) {
            $appID = $child.Tag
            Write-Output "Instalace aplikace: $($child.Content) ($appID)"
            Start-Process -FilePath "winget" -ArgumentList "install $appID" -Wait
        }
    }
    Write-Output "Instalace dokoncena."
})

$uninstallButton = $window.FindName("UninstallButton")
$uninstallButton.Add_Click({
    Write-Output "Odinstalace aplikaci..."
    $appList = $window.FindName("AppList")
    foreach ($child in $appList.Children) {
        if ($child.IsChecked -eq $true) {
            $appID = $child.Tag
            Write-Output "Odinstalace aplikace: $($child.Content) ($appID)"
            Start-Process -FilePath "winget" -ArgumentList "uninstall $appID" -Wait
        }
    }
    Write-Output "Odinstalace dokoncena."
})

# Tlacitko pro verze
$versionButton = $window.FindName("VersionButton")
$versionButton.Add_Click({
    $versionWindow = New-Object System.Windows.Window
    $versionWindow.Title = "Verze ProgramZelva ToolBox"
    $versionWindow.Width = 600
    $versionWindow.Height = 300
    $versionWindow.ResizeMode = 'CanResize'

    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = "ProgramZelva ToolBox pre-release 1.0`n
Tato verze je urcena pro testovani."
    $textBlock.HorizontalAlignment = 'Center'
    $textBlock.VerticalAlignment = 'Center'

    $versionWindow.Content = $textBlock
    $versionWindow.ShowDialog()
})

# Zobrazeni okna
$window.ShowDialog()
