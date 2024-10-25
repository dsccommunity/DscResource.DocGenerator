function Get-ClassPropertyCustomAttribute {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Reflection.CustomAttributeData[]]
        $Attributes,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AttributeType
    )

    process {
        return $Attributes | Where-Object {$_.AttributeType.Name -eq $AttributeType}
    }
}
