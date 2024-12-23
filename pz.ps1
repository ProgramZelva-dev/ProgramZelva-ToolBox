Write-Output "Starting ProgramZelva ToolBox..."
 
# Nastaveni bufferu a okna PowerShell
$bufferWidth = 120
$bufferHeight = 300  # Dostatecne velky buffer
$Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size($bufferWidth, $bufferHeight)

$windowWidth = 120
$windowHeight = 30  # Rozumna velikost okna, mensi nez buffer
$Host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size($windowWidth, $windowHeight)

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
            <ListBoxItem Content='Multimedia Tools' Foreground='Black'/>
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

# Cesta k souboru aplikaci (relativni cesta k aktualnimu adresari)
$applicationsFilePath = Join-Path (Get-Location) "applications.json"

# Kontrola, zda soubor aplikaci existuje
if (-not (Test-Path $applicationsFilePath)) {
    Write-Error "Soubor aplikaci nebyl nalezen!"
    return
}

# Nacteni aplikaci z JSON souboru
$applications = Get-Content -Path $applicationsFilePath | ConvertFrom-Json

# Funkce pro zobrazeni aplikaci podle kategorie
function ShowApplications($category) {
    $appList = $window.FindName("AppList")
    if ($appList -eq $null) {
        Write-Error "AppList nebyl nalezen."
        return
    }
    $appList.Children.Clear()

    # Zobrazeni aplikaci pro danou kategorii
    if ($applications.PSObject.Properties.Match($category).Count -gt 0) {
        $categoryApplications = $applications.$category
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

# Inicialni kategorie
Write-Output "Zobrazeni aplikaci pro inicialni kategorii..."
ShowApplications "Browsers"

# Kategorie z ListBoxu
$categoryList = $window.FindName("CategoryList")
if ($categoryList -eq $null) {
    Write-Error "Kategorie List nebyla nalezena."
    return
}
$categoryList.add_SelectionChanged({
    $selectedCategory = $categoryList.SelectedItem.Content
    if ($selectedCategory -and $applications.PSObject.Properties.Match($selectedCategory).Count -gt 0) {
        ShowApplications $selectedCategory
    } else {
        Write-Output "Vybrana kategorie '$selectedCategory' neni platna."
    }
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

# Tlacitko pro zobrazeni verze
$versionButton = $window.FindName("VersionButton")
$versionButton.Add_Click({
    $versionWindow = New-Object System.Windows.Window
    $versionWindow.Title = "Version ProgramZelva ToolBox"
    $versionWindow.Width = 600
    $versionWindow.Height = 300
    $versionWindow.WindowStartupLocation = 'CenterScreen'
    $versionWindow.ResizeMode = 'CanResize'
    $versionWindow.MinWidth = 400
    $versionWindow.MinHeight = 200

    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = "ProgramZelva ToolBox pre-release 1.0`n
This version is for testing and development.`n
More applications planned for version 1.1.`n"
    $textBlock.HorizontalAlignment = 'Center'
    $textBlock.VerticalAlignment = 'Center'

    $versionWindow.Content = $textBlock
    $versionWindow.ShowDialog()
})

# Zobrazeni okna
try {
    $window.ShowDialog()
    Write-Output "Okno zobrazeno uspesne."
} catch {
    Write-Error "Nepodarilo se zobrazit okno: $_"
}
