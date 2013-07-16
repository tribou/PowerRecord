# Migration Template
# Migration returns $true if successful
# Run migration example: .\db_migration_20130304_example.ps1 -up -dsn "ODBC-Datasource"

param(
    [string]$Dsn,
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

$ConnectionsToUse = @()
if($Dsn -eq "") {
  foreach($conn in ($Global:DatabaseConnections).ConnectionString) {
    $ConnectionsToUse += ($conn -replace "DSN=","")
  }
} else {
  $ConnectionsToUse += $Dsn
}

########################################################################
######################## EDIT FROM HERE DOWN ###########################
########################################################################

foreach ($db in $ConnectionsToUse) {

  # The UP migration
  if($Up) {
    
    # Comment out the following two lines if this migration supports UP
    #=pre_query_up

    # Build query
    $queries = @(
      <# "CREATE TABLE IF NOT EXISTS some_table ( `
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `
        name VARCHAR(255) );" #>
      #=query_up
    )

    # Execute query
    foreach($query in $queries) {
      NoResult-Query -Dsn $db -Query $query
    }

    #=post_query_up
    return $true
  }


  # The DOWN migration
  if($Down) {
    
    # Comment out the following two lines if this migration supports DOWN
    #=pre_query_down

    # Build query
    $queries = @(
      <# "DROP TABLE IF EXISTS some_table;" #>
      #=query_down
    )

    # Execute query
    foreach($query in $queries) {
      NoResult-Query -Dsn $db -Query $query
    }

    #=post_query_down
    return $true
  }
}
