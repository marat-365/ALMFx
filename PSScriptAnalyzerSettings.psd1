@{
    Severity     = @('Error', 'Warning')

    # Add exclusions here only with a comment explaining why.
    ExcludeRules = @()

    Rules        = @{
        PSPlaceOpenBrace      = @{
            Enable     = $true
            OnSameLine = $true
        }
        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
        }
    }
}
