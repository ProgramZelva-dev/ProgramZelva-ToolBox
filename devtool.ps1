Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- OKNO (ŠIRŠÍ) ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "PZ Installer"
$form.Size = New-Object System.Drawing.Size(900,520)
$form.MinimumSize = New-Object System.Drawing.Size(900,520)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# --- INPUT ---
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Width = 650
$textBox.Location = New-Object System.Drawing.Point(120,30)
$textBox.Font = New-Object System.Drawing.Font("Segoe UI",13)
$textBox.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$textBox.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($textBox)

# --- SEARCH ---
$searchBtn = New-Object System.Windows.Forms.Button
$searchBtn.Text = "Search"
$searchBtn.Location = New-Object System.Drawing.Point(390,70)
$searchBtn.Size = New-Object System.Drawing.Size(100,35)
$searchBtn.BackColor = [System.Drawing.Color]::FromArgb(55,55,55)
$searchBtn.ForeColor = [System.Drawing.Color]::White
$searchBtn.FlatStyle = "Flat"
$form.Controls.Add($searchBtn)

# --- LIST ---
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(860,320)
$listBox.Location = New-Object System.Drawing.Point(20,120)
$listBox.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
$listBox.ForeColor = [System.Drawing.Color]::White
$listBox.BorderStyle = "None"
$listBox.Font = New-Object System.Drawing.Font("Consolas",11)
$listBox.ItemHeight = 24
$form.Controls.Add($listBox)

# --- INSTALL ---
$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "Install"
$installBtn.Location = New-Object System.Drawing.Point(390,450)
$installBtn.Size = New-Object System.Drawing.Size(100,35)
$installBtn.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$installBtn.ForeColor = [System.Drawing.Color]::White
$installBtn.FlatStyle = "Flat"
$installBtn.Visible = $false
$form.Controls.Add($installBtn)

# --- DATA ---
$ids = @()

function DoSearch {
    $listBox.Items.Clear()
    $ids = @()
    $installBtn.Visible = $false

    $query = $textBox.Text
    if ($query -eq "") { return }

    try {
        $lines = winget search $query | Select-Object -Skip 2

        foreach ($line in $lines) {
            if ($line.Trim() -eq "") { continue }

            $parts = $line -split "\s{2,}"

            if ($parts.Length -ge 3) {
                $name = $parts[0]
                $id = $parts[1]
                $source = $parts[-1]

                $ids += $id

                # 🔥 NAME vlevo, SOURCE úplně vpravo
                $row = "{0,-60}{1,10}" -f $name, $source
                $listBox.Items.Add($row)
            }
        }

        if ($listBox.Items.Count -gt 0) {
            $installBtn.Visible = $true
        }

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Search failed")
    }
}

# EVENTS
$searchBtn.Add_Click({ DoSearch })

$textBox.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") {
        DoSearch
    }
})

$installBtn.Add_Click({
    $index = $listBox.SelectedIndex
    if ($index -lt 0) { return }

    $id = $ids[$index]
    Start-Process powershell -ArgumentList "winget install --id $id -e" -Verb RunAs
})

$form.ShowDialog()
