function Export-CustomCSV ($ExportTo) {
    try {
        $csv | Export-CSV $ExportTo -NoTypeInformation
        $wpf.SF7N.Title = 'SF7N Interface'
        $wpf.Commit.IsEnabled = $false
    } catch {Write-Log 'ERR' "Export CSV Failed: $_"}
}

function Add-Row ($Action) {
    # Prepare blank template for inserting
    $RowTemplate = [PSCustomObject] @{}
    $csvHeader.Foreach{$RowTemplate | Add-Member NoteProperty $_ ''}

    # Execute preparations for each type of insert
    try {$At = $csv.IndexOf($wpf.CSVGrid.SelectedItem)} catch {$At = 0}
    try {$Count = $wpf.CSVGrid.SelectedItems.Count}     catch {$Count = 1}
    
    if ($Action -eq 'InsertBelow') {$At += $Count}

    if ($Action -eq 'InsertLast') {
        $Count = $wpf.InsertLastCount.Text
        for ($I = 0; $I -lt $Count; $I++) {
            # Add rows at end with IDing
            $ThisRow = $RowTemplate.PsObject.Copy()
            $ThisRow.($csvHeader[0]) = $config.AppendFormat -replace
                '%D', (Get-Date -Format yyyyMMdd) -replace
                '%T', (Get-Date -Format HHmmss)   -replace
                '%#', $I
            if ($csv) {
                $csv.Add($ThisRow)
            } else {
                [Collections.ArrayList] $script:csv = @($ThisRow)
            }
        }
        $wpf.CSVGrid.ScrollIntoView($wpf.CSVGrid.Items[-1], $wpf.CSVGrid.Columns[0])

    } else {
        # Max & Min functions to prevent under/overflowing
        $csv.InsertRange([Math]::Max(0,[Math]::Min($At,$csv.Count)), @($RowTemplate) * $Count)
    }

    $wpf.CSVGrid.ItemsSource = $csv
    $wpf.CSVGrid.Items.Refresh()
}
