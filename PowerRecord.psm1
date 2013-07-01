# PowerRecord Database Functions for PowerShell

$DatabaseConnections = @()

function Connect-Database {
  <#
  
  .PARAMETER Dsn
  The ODBC driver that will be used to connect to a database.
  
  .Example
  Connect-Database "ODBC-Datasource"
  
  #>
  
  param(
    [Parameter(Position=0,Mandatory=1)]
    [string]$Dsn
  )
  
  try {
    $db = New-Object System.Data.ODBC.ODBCConnection("DSN=$($Dsn)") -ErrorAction "Stop"
    $Global:DatabaseConnections += $db
    Write-Host "Successfully loaded $($Dsn)!"
  }
  catch {
    return "Unable to establish database connection to $($Dsn): $($error[0].Exception.Message)"
  }
}

function NoResult-Query {
  
  <#
  
  .PARAMETER Dsn
  The name of the database connection to use that was imported with Connect-Database.  If no Dsn is specified, 
  the query will be sent to all currently connected databases.
  
  .PARAMETER Query
  The statement to use on the database that returns no results.
  
  .Example
  $InsertStatement = "INSERT INTO table_name (column1,column2,column3,...) VALUES (value1,value2,value3,...);"
  NoResult-Query -Dsn "ODBC-Datasource" -Query $InsertStatement
  
  .Example
  $DeleteStatement = "DELETE FROM table_name WHERE some_column=some_value;"
  NoResult-Query -Dsn "ODBC-Datasource" -Query $DeleteStatement
  
  .Example
  $UpdateStatement = "UPDATE table_name SET column1=value1,column2=value2,... WHERE some_column=some_value;"
  NoResult-Query -Dsn "ODBC-Datasource" -Query $UpdateStatement
  
  #>
  
  param(
    [Parameter(Position=0,Mandatory=0)]
    [string]$Dsn="",
    [Parameter(Position=1,Mandatory=1)]
    [string]$Query
  )
  
  if(($Global:DatabaseConnections | Measure).Count -lt 1){
    return "No database connections found.  Import a new connection using Connect-Database first."
  }
  
  $ConnectionsToUse = @()
  if($Dsn -eq "") {
    $ConnectionsToUse += $Global:DatabaseConnections
  } else {
    $ConnectionsToUse += $Global:DatabaseConnections | Where Name -eq $Dsn
    if(($ConnectionsToUse | Measure).Count -lt 1){
      return "No currently loaded database connections matched $($Dsn)."
    }
  }
  
  foreach ($db in $ConnectionsToUse) {
  
    $cmd = $db.createCommand()
    $db.Open()
    $cmd.commandText = $Query
    $reader = $cmd.ExecuteReader()
    $reader.Close()
    $db.Close()
  
  }
  
}

function Result-Query {
  
  <#
  
  .PARAMETER Dsn
  The name of the database connection to use that was imported with Connect-Database.  If no Dsn is specified, 
  the query will be sent to all currently connected databases.
  
  .PARAMETER Query
  The statement which returns results from the database.
  
  .Example
  $SelectStatement = "SELECT column_name,column_name FROM table_name;"
  $result = Result-Query -Dsn "ODBC-Datasource" -Query $SelectStatement
  if(($result | Measure).Count -lt 1) {
    return "Query returned no results."
  } else {
    return $result | ft -auto
  }
  
  #>
  
  param(
    [Parameter(Position=0,Mandatory=0)]
    [string]$Dsn="",
    [Parameter(Position=1,Mandatory=1)]
    [string]$Query
  )
  
  if(($Global:DatabaseConnections | Measure).Count -lt 1){
    return "No database connections found.  Import a new connection using Connect-Database first."
  }
  
  $ConnectionsToUse = @()
  if($Dsn -eq "") {
    $ConnectionsToUse += $Global:DatabaseConnections
  } else {
    $ConnectionsToUse += $Global:DatabaseConnections | Where Name -eq $Dsn
    if(($ConnectionsToUse | Measure).Count -lt 1){
      return "No currently loaded database connections matched $($Dsn)."
    }
  }
  
  foreach ($db in $ConnectionsToUse) {
  
    $cmd = $db.createCommand()
    $cmd.commandText = $Query
    $db.Open()
    $reader = $cmd.ExecuteReader()
    $out = @()
    # Convert each row into an object, using the column names from the database to create object properties.
    while ($reader.Read()) {
      $newObj = New-Object System.Object
      for ($i = 0;$i -lt $reader.FieldCount;$i++) {
        $newObj | Add-Member -MemberType NoteProperty -Name "$($reader.GetName($i))" -Value $reader.GetValue($i)
      }
      $out += $newObj
    }
    $reader.Close()
    $db.Close()
    if ($out.Count -ne 0) {
      return $out
    } else {
      return @()
    }

  }
  
}

function Show-Connections {
  
  if(($Global:DatabaseConnections | Measure).Count -lt 1) {
    return "No databases currently connected."
  } else {
    return $Global:DatabaseConnections
  }
}

Export-ModuleMember -Function Connect-Database -Alias Connect-Database -Cmdlet Connect-Database
Export-ModuleMember -Function NoResult-Query -Alias NoResult-Query -Cmdlet NoResult-Query
Export-ModuleMember -Function Result-Query -Alias Result-Query -Cmdlet Result-Query
Export-ModuleMember -Function Show-Connections -Alias Show-Connections -Cmdlet Show-Connections
Export-ModuleMember -Variable DatabaseConnections
