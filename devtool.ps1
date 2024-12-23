# Starting Program
Write-Output "Starting ProgramZelva ToolBox..."

# Načtení WPF
Add-Type -AssemblyName PresentationFramework

# Vytvoření okna
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
                <!-- Naplní se programy -->
            </StackPanel>
        </ScrollViewer>

        <!-- Tlačítka -->
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

# Načtení XAML a vytvoření GUI
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Error "Nepodařilo se načíst okno z XAML: $_"
    return
}

# URL k JSON souboru
$url = "https://raw.githubusercontent.com/ProgramZelva-dev/ProgramZelva-ToolBox/main/applications.json"

# Načtení aplikací z URL
try {
    $jsonData = Invoke-RestMethod -Uri $url -Method Get
} catch {
    Write-Error "Nepodařilo se načíst data z URL: $_"
    return
}

# Funkce pro zobrazení aplikací podle kategorie
function ShowApplications($category) {
    $appList = $window.FindName("AppList")
    if ($appList -eq $null) {
        Write-Error "AppList nebyl nalezen."
        return
    }
    $appList.Children.Clear()

    # Zobrazení aplikací pro danou kategorii
    if ($jsonData.PSObject.Properties.Match($category).Count -gt 0) {
        $categoryApplications = $jsonData.$category
        foreach ($app in $categoryApplications) {
            $checkBox = New-Object System.Windows.Controls.CheckBox
            $checkBox.Content = $app.Name
            $checkBox.Tag = $app.WingetID
            $checkBox.Foreground = [System.Windows.Media.Brushes]::Black
            $appList.Children.Add($checkBox)
        }
    }
}

# Zobrazení výchozí kategorie
ShowApplications "Browsers"

# Kategorie z ListBoxu
$categoryList = $window.FindName("CategoryList")
if ($categoryList -eq $null) {
    Write-Error "Kategorie List nebyla nalezena."
    return
}
$categoryList.add_SelectionChanged({
    $selectedCategory = $categoryList.SelectedItem.Content
    if ($selectedCategory -and $jsonData.PSObject.Properties.Match($selectedCategory).Count -gt 0) {
        ShowApplications $selectedCategory
    }
})

# Funkce pro práci s tlačítky
function InstallSelectedApps {
    $appList = $window.FindName("AppList")
    foreach ($child in $appList.Children) {
        if ($child.IsChecked -eq $true) {
            $appName = $child.Content
            $wingetID = $child.Tag
            Write-Output "Instaluji aplikaci: $appName (Winget ID: $wingetID)"
            Start-Process -Wait -FilePath "winget" -ArgumentList "install --id $wingetID"
        }
    }
}

function UninstallSelectedApps {
    $appList = $window.FindName("AppList")
    foreach ($child in $appList.Children) {
        if ($child.IsChecked -eq $true) {
            $appName = $child.Content
            $wingetID = $child.Tag
            Write-Output "Odinstalovávám aplikaci: $appName (Winget ID: $wingetID)"
            Start-Process -Wait -FilePath "winget" -ArgumentList "uninstall --id $wingetID"
        }
    }
}

function ShowVersionInfo {
    $appList = $window.FindName("AppList")
    foreach ($child in $appList.Children) {
        if ($child.IsChecked -eq $true) {
            $appName = $child.Content
            $wingetID = $child.Tag
            Write-Output "Zjišťuji verzi aplikace: $appName (Winget ID: $wingetID)"
            Start-Process -NoNewWindow -Wait -FilePath "winget" -ArgumentList "show --id $wingetID"
        }
    }
}

# Připojení tlačítek
$installButton = $window.FindName("InstallButton")
$installButton.Add_Click({ InstallSelectedApps })

$uninstallButton = $window.FindName("UninstallButton")
$uninstallButton.Add_Click({ UninstallSelectedApps })

$versionButton = $window.FindName("VersionButton")
$versionButton.Add_Click({ ShowVersionInfo })

# Zobrazení okna
try {
    $window.ShowDialog()
} catch {
    Write-Error "Nepodařilo se zobrazit okno: $_"
}
