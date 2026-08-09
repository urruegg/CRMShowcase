$script:SafeCliDiagnosticDefaultMaxLength = 240
$script:SafeCliErrorDefaultMaxLength = 400
$script:SafeCliDiagnosticTruncationMarker = ' ...[truncated]... '

function Get-SafeCliDiagnosticText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [string]) {
        return $Value
    }

    if ($Value -is [System.Management.Automation.ErrorRecord]) {
        if ($null -ne $Value.Exception -and
            -not [string]::IsNullOrWhiteSpace([string]$Value.Exception.Message)) {
            return [string]$Value.Exception.Message
        }

        return [string]$Value
    }

    if ($Value -is [System.Exception]) {
        return [string]$Value.Message
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return [string]$Value
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $parts = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $Value) {
            $text = Get-SafeCliDiagnosticText -Value $item
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                [void]$parts.Add([string]$text)
            }
        }

        return ($parts.ToArray() -join [Environment]::NewLine)
    }

    return [string]$Value
}

function Remove-SafeCliAnsiEscapeSequences {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    $pattern = '[\u001B\u009B][[\]()#;?]*(?:(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-ntqry=><~]|(?:[^\u001B\u009B]*)(?:\u0007|\u001B\\))'
    return [regex]::Replace($Text, $pattern, '')
}

function ConvertTo-SafeCliDiagnosticLine {
    [CmdletBinding()]
    param(
        [AllowNull()]
        $Value,

        [ValidateRange(24, 8192)]
        [int]$MaxLength = $script:SafeCliDiagnosticDefaultMaxLength,

        [string]$EmptyText = '<no output>'
    )

    $text = Get-SafeCliDiagnosticText -Value $Value
    $text = Remove-SafeCliAnsiEscapeSequences -Text $text

    if ([string]::IsNullOrEmpty($text)) {
        return $EmptyText
    }

    $text = $text -replace "[`r`n`t]+", ' '
    $text = [regex]::Replace(
        $text,
        '[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]',
        ' '
    )
    $text = [regex]::Replace($text, '\s+', ' ').Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $EmptyText
    }

    if ($text.StartsWith('::', [System.StringComparison]::Ordinal)) {
        $text = "'$text"
    }

    if ($text.Length -le $MaxLength) {
        return $text
    }

    $marker = $script:SafeCliDiagnosticTruncationMarker
    if ($marker.Length -ge $MaxLength) {
        return $marker.Substring(0, $MaxLength)
    }

    $availableLength = $MaxLength - $marker.Length
    $headLength = [Math]::Max([int][Math]::Ceiling($availableLength * 0.7), 1)
    $tailLength = [Math]::Max($availableLength - $headLength, 0)
    if ($headLength -gt $text.Length) {
        $headLength = $text.Length
        $tailLength = 0
    }
    elseif ($tailLength -gt ($text.Length - $headLength)) {
        $tailLength = $text.Length - $headLength
    }

    $head = $text.Substring(0, $headLength).TrimEnd()
    if ($tailLength -le 0) {
        return $head + $marker
    }

    $tail = $text.Substring($text.Length - $tailLength).TrimStart()
    if ([string]::IsNullOrEmpty($tail)) {
        return $head + $marker
    }

    return $head + $marker + $tail
}

function Get-SafeCliErrorMessage {
    [CmdletBinding()]
    param(
        [AllowNull()]
        $ErrorRecord,

        [ValidateRange(24, 8192)]
        [int]$MaxLength = $script:SafeCliErrorDefaultMaxLength,

        [string]$Fallback = 'Unexpected failure.'
    )

    $messageSource = if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
        if ($null -ne $ErrorRecord.Exception -and
            -not [string]::IsNullOrWhiteSpace([string]$ErrorRecord.Exception.Message)) {
            $ErrorRecord.Exception.Message
        }
        else {
            [string]$ErrorRecord
        }
    }
    elseif ($ErrorRecord -is [System.Exception]) {
        $ErrorRecord.Message
    }
    else {
        $ErrorRecord
    }

    return ConvertTo-SafeCliDiagnosticLine `
        -Value $messageSource `
        -MaxLength $MaxLength `
        -EmptyText $Fallback
}

function Write-SafeCliErrorLine {
    [CmdletBinding()]
    param(
        [AllowNull()]
        $ErrorRecord,

        [ValidateRange(24, 8192)]
        [int]$MaxLength = $script:SafeCliErrorDefaultMaxLength,

        [string]$Fallback = 'Unexpected failure.'
    )

    [Console]::Error.WriteLine(
        (Get-SafeCliErrorMessage `
            -ErrorRecord $ErrorRecord `
            -MaxLength $MaxLength `
            -Fallback $Fallback)
    )
}
