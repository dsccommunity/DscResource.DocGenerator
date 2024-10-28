

# takes a System.RuntimeType - a System.Reflection.PropertyInfo .PropertyType

# Check PropertyType.Name = 'Nullable`1'
# Get value from GenericTypeArgument.FullName

# else return FullName

function Get-DscPropertyType
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Type]
        $PropertyType
    )

    switch ($PropertyType.Name)
    {
        'Nullable`1'
        {
            return $PropertyType.GenericTypeArguments.Name
        }
        default
        {
            return $PropertyType.Name
        }
    }
}
