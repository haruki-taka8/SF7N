#—————————————————————————————————————————————————————————————————————————————+—————————————————————
# Search-related actions
$wpf.Search.Add_Click({Search-CSV $wpf.SearchRules.Text})
$wpf.SearchRules.Add_TextChanged({
    if ($wpf.TabSearch.IsChecked -and ($wpf.SearchRules.Text[-1] -eq "`t")) {
        Search-CSV $wpf.SearchRules.Text
    }
}) 


$wpf.CSVGrid.Add_MouseUp({Set-Preview})
$wpf.CSVGrid.Add_Keyup({Set-Preview})

$wpf.ResetSorting.Add_Click({
    $wpf.CSVGrid.Items.SortDescriptions.Clear()
    $wpf.CSVGrid.Columns.ForEach({$_.SortDirection = $null})
})

$wpf.ReadOnly.Add_Click({
    $wpf.CSVGrid.IsReadOnly = $wpf.ReadOnly.IsChecked
    $wpf.CurrentMode.Text = 'Search Mode'
    if ($wpf.ReadOnly.IsChecked) {
        $wpf.ReadOnlyText.Text = '(R/O)'
    } else {
        $wpf.ReadOnlyText.Text = '(R/W)'
    }
})

$wpf.TabSearch.Add_Click({
    $config.TabSearch = !$config.TabSearch
})