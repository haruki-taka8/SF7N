function Write-Log ($Type, $Content) {
    if ($Type -eq 'ERR') {
        [Void] [Windows.MessageBox]::Show($Content, 'SF7N Interface', 'OK', 'Error')
    }
    $TimeDiff = ((Get-Date)-$startTime).TotalMilliseconds.
                    ToString().Split('.')[0].  # Get integral part
                    PadRight(5)                # Right padding
    Write-Host "$TimeDiff    $Type    $Content" | Out-Host
}

function Import-CustomCSV ($ImportFrom) {
    <#
        Creates following variables:
        - csvHeader    [Array] Header of the CSV
        - csv          [AList] Content from CSV
        - csvAlias     [AList] Aliases for CSV
    #>
    Write-Log 'INF' 'Import CSV'
    $ImportFrom = $ExecutionContext.InvokeCommand.ExpandString($ImportFrom)

    $script:csvHeader = (Get-Content $ImportFrom -First 1).Replace('"', '').Split(',')
    [Collections.ArrayList] $script:csv = Import-CSV $ImportFrom
    
    $Alias = '.\Configurations\CSVAlias.csv'
    if (Test-Path $Alias) {$script:csvAlias = Import-CSV $Alias}

    # Enter edit mode if CSV is empty
    if (!$csvHeader) {
        Write-Log 'ERR' 'CSV is empty; SF7N will exit.'
        $wpf.SF7N.Close()

    } elseif (!$csv) {
        $wpf.Toolbar.SelectedIndex = 1
    }
}

function New-SaveDialog {
    [Windows.MessageBox]::Show('Commit changes before exiting?', 'SF7N Interface', 'YesNoCancel', 'Question')
}

function Set-DataContext ($Key, $Value) {
    # Because I do not know how to implement INotifyPropertyChanged
    $context.$Key = $Value
    $wpf.SF7N.DataContext = $null
    $wpf.SF7N.DataContext = $context
}

function Import-Configuration {
    # Read and evaluate path configurations
    Write-Log 'INF' 'Import Configurations'
    $script:config = Get-Content .\Configurations\General.ini | ConvertFrom-StringData

    # Bulid DataContext
    Write-Log 'INF' 'Build  DataContext'
        $script:context = [PSCustomObject] @{
        csvLocation  = $Config.csvLocation
        PreviewPath  = $Config.PreviewPath
        Theme        = $Config.Theme
        InputAlias   = $Config.InputAlias -ieq 'true'
        AppendFormat = $Config.AppendFormat
        AppendCount  = $Config.AppendCount
        OutputAlias  = $Config.OutputAlias   -ieq 'true'
        RawMode      = $Config.RawMode   -ieq 'true'
        ReadWrite    = $Config.ReadWrite   -ieq 'true'
        Status       = 'Initializing'
        Preview      = $null
    }
}

function Initialize-SF7N {
    Import-Configuration

    # Apply DataContext to GUI
    Write-Log 'INF' 'Apply  DataContext to GUI'
    $wpf.SF7N.DataContext = $context
    $wpf.SF7N.Dispatcher.Invoke([Action]{}, 'Render')

    Import-CustomCSV $context.csvLocation
    $wpf.CSVGrid.ItemsSource = $null
    $wpf.CSVGrid.Columns.Clear()
    
    # Generate columns of Datagrid
    Write-Log 'INF' 'Build  Datagrid'
    $Format = '.\Configurations\Formatting.csv'
    if (Test-Path $Format) {$Format = Import-CSV $Format}

    $csvHeader.ForEach{
        $Column = [Windows.Controls.DataGridTextColumn]::New()
        $Column.Binding = [Windows.Data.Binding]::New($_)
        $Column.Header  = $_
        $Column.CellStyle = [Windows.Style]::New()

        # Apply conditional formatting
        for ($i = 0; $i -lt $Format.$_.Count; $i += 2) {
            if ($Format.$_[$i] -match '^\s*$') {break}
            $Trigger = [Windows.DataTrigger]::New()
            $Trigger.Binding = $Column.Binding
            $Trigger.Value = $Format.$_[$i]
            $Trigger.Setters.Add([Windows.Setter]::New(
                [Windows.Controls.DataGridCell]::BackgroundProperty,
                [Windows.Media.BrushConverter]::New().ConvertFromString($Format.$_[$i+1])
            ))
            $Column.CellStyle.Triggers.Add($Trigger)
        }
        $wpf.CSVGrid.Columns.Add($Column)
    }
    Search-CSV $wpf.SearchBar.Text -FirstRun $true
}
