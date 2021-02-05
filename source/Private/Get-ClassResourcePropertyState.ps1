function Get-ClassResourcePropertyState
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.Language.PropertyMemberAst]
        $Ast
    )

    $astFilter = {
        $args[0] -is [System.Management.Automation.Language.NamedAttributeArgumentAst]
    }

    $propertyNamedAttributeArgumentAsts = $Ast.FindAll($astFilter, $true)

    $isKeyProperty = 'Key' -in $propertyNamedAttributeArgumentAsts.ArgumentName
    $isMandatoryProperty = 'Mandatory' -in $propertyNamedAttributeArgumentAsts.ArgumentName
    $isReadProperty = 'NotConfigurable' -in $propertyNamedAttributeArgumentAsts.ArgumentName

    if ($isKeyProperty)
    {
        $propertyState = 'Key'
    }
    elseif ($isMandatoryProperty)
    {
        $propertyState = 'Required'
    }
    elseif ($isReadProperty)
    {
        $propertyState = 'Read'
    }
    else
    {
        $propertyState = 'Write'
    }

    return $propertyState
}
