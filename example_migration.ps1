# Migration - Example Template for Future Migrations
# Migration returns $true if successful
# Run migration example: .\db_migration_20130304_example.ps1 -up -dsn "ODBC-Datasource"

param(
    [Parameter(Mandatory=$true)][string]$Dsn,
    [switch]$Up,
    [switch]$Down
)

if($Up -AND $Down) { 
    throw "You may only use -up or -down, not both." 
    exit
} elseif(!$Up -AND !$Down) {
    throw "Please specify either -up or -down for the migration."
    exit
}


# Check dependencies
if((Get-Module PowerRecord | Measure).Count -lt 1) {
  return "Import PowerRecord module before running this migration."
}

########################################################################
######################## EDIT FROM HERE DOWN ###########################
########################################################################

# The UP migration
if($Up) {
    
    # Comment out the following two lines if this migration supports UP
    throw "This migration does not support -Up yet."
    return $false
    
    # Build query
    $queries = @(
        "CREATE TABLE IF NOT EXISTS some_table ( `
            id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `
            name VARCHAR(255) );"
    )
    
    # Execute query
    foreach($query in $queries) {
        NoResult-Query -Dsn $Dsn -Query $query
    }
    
    return $true
}


# The DOWN migration
if($Down) {
    
    # Comment out the following two lines if this migration supports DOWN
    throw "This migration does not support -Down yet."
    return $false
    
    # Build query
    $queries = @(
        "DROP TABLE IF EXISTS some_table;"
    )
    
    # Execute query
    foreach($query in $queries) {
        NoResult-Query -Dsn $Dsn -Query $query
    }
    
    return $true
}