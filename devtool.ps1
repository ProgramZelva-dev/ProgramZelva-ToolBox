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
            <ListBoxItem Content='Prohlížeče' Foreground='Black'/>
            <ListBoxItem Content='Komunikace' Foreground='Black'/>
            <ListBoxItem Content='Multimediální nástroje' Foreground='Black'/>
            <ListBoxItem Content='Nástroje pro Windows' Foreground='Black'/>
            <ListBoxItem Content='Pracovní nástroje' Foreground='Black'/>
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

# URL souboru aplikací
$applicationsUrl = "https://raw.githubusercontent.com/ProgramZelva-dev/ProgramZelva-ToolBox/main/applications.json"

# Načtení aplikací z JSON souboru z webu
try {
    Write-Output "Načítám aplikace z URL: $applicationsUrl"

    # Získání obsahu z URL
    $response = Invoke-WebRequest -Uri $applicationsUrl -UseBasicParsing
    
    if ($response.StatusCode -eq 200) {
        # Parsování obsahu jako JSON
        $applications = $response.Content | ConvertFrom-Json
        Write-Output "Aplikace byly úspěšně načteny z URL."
    } else {
        Write-Error "Chybný stavový kód HTTP: $($response.StatusCode)"
        return
    }
} catch {
    Write-Error "Chyba při načítání JSON souboru z URL: $_"
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
    if ($applications.PSObject.Properties.Match($category).Count -gt 0) {
        $categoryApplications = $applications.$category
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
ShowApplications "Prohlížeče"

# Kategorie z ListBoxu
$categoryList = $window.FindName("CategoryList")
if ($categoryList -eq $null) {
    Write-Error "Kategorie List nebyla nalezena."
    return
}

# Připojení události pro změnu výběru kategorie
$categoryList.add_SelectionChanged({
    $selectedCategory = $categoryList.SelectedItem.Content
    if ($selectedCategory -and $applications.PSObject.Properties.Match($selectedCategory).Count -gt 0) {
        ShowApplications $selectedCategory
    }
})

# Tlačítka pro instalaci a odinstalaci
$installButton = $window.FindName("InstallButton")
$installButton.Add_Click({
    Write-Output "Instalace aplikací..."
    $appList = $window.FindName("AppList")
    foreach ($child in $appList.Children) {
        if ($child.IsChecked -eq $true) {
            $appID = $child.Tag
            Write-Output "Instalace aplikace: $($child.Content) ($appID)"
            Start-Process -FilePath "winget" -ArgumentList "install $appID" -Wait
        }
    }
})

$uninstallButton = $window.FindName("UninstallButton")
$uninstallButton.Add_Click({
    Write-Output "Odinstalace aplikací..."
    $appList = $window.FindName("AppList")
    foreach ($child in $appList.Children) {
        if ($child.IsChecked -eq $true) {
            $appID = $child.Tag
            Write-Output "Odinstalace aplikace: $($child.Content) ($appID)"
            Start-Process -FilePath "winget" -ArgumentList "uninstall $appID" -Wait
        }
    }
})

$versionButton = $window.FindName("VersionButton")
$versionButton.Add_Click({
    $versionWindow = New-Object System.Windows.Window
    $versionWindow.Title = "Verze ProgramZelva ToolBox"
    $versionWindow.Width = 600
    $versionWindow.Height = 300
    $versionWindow.WindowStartupLocation = 'CenterScreen'

    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = "ProgramZelva ToolBox pre-release 1.0`nTato verze je určena pro testování a vývoj.`nNeobsahuje moc aplikací, ale je plánováno přidání více aplikací ve verzi 1.1.`n"
    $textBlock.HorizontalAlignment = 'Center'
    $textBlock.VerticalAlignment = 'Center'

    $versionWindow.Content = $textBlock
    $versionWindow.ShowDialog()
})

# Zobrazení okna
try {
    $window.ShowDialog()
} catch {
    Write-Error "Nepodařilo se zobrazit okno: $_"
}
