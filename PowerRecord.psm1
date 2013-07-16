# PowerRecord Database Functions for PowerShell

$ODBCConnections = @()

function Connect-ODBC {
  <#
  
  .PARAMETER Dsn
  The ODBC driver that will be used to connect to a database.
  
  .Example
  Connect-ODBC "ODBC-Datasource"
  
  #>
  
  param(
    [Parameter(Position=0,Mandatory=1)]
    [string]$Dsn
  )
  
  try {
    $db = New-Object System.Data.ODBC.ODBCConnection("DSN=$($Dsn)") -ErrorAction "Stop"
    $Global:ODBCConnections += $db
    Write-Host "Successfully loaded $($Dsn)!"
  }
  catch {
    return "Unable to establish database connection to $($Dsn): $($error[0].Exception.Message)"
  }
}

function Disconnect-ODBC {
  <#
  
  .PARAMETER Dsn
  The ODBC driver that will be used to connect to a database.
  
  .Example
  Disconnect-ODBC ODBC-Datasource
  
  .Example
  Disconnect-ODBC -All
  
  #>
  
  param(
    [Parameter(ParameterSetName="Specific",Position=0,Mandatory=1)]
    [string]$Dsn,
    [Parameter(ParameterSetName="All",Position=0,Mandatory=1)]
    [switch]$All
  )
  
  try {
    if(($Global:ODBCConnections | Measure).Count -gt 0) {
      if($All) {
        foreach($connection in $Global:ODBCConnections) {
          $name = $($connection.ConnectionString) -replace "DSN="
          Write-Host "Disconnected $($name)"
        }
        $Global:ODBCConnections = $()
      } else {
        $db = ("DSN=$($Dsn)")
        if(($Global:ODBCConnections | Where {$_.ConnectionString -eq $db} | Measure).Count -gt 0) {
          $Global:ODBCConnnections = $Global:ODBCConnections | Where {$_.ConnectionString -ne $db}
          Write-Host "Disconnected $($Dsn)"
        } else {
          Write-Host "No currently loaded database connections matched $($Dsn)."
        }
      }
    } else {
      Write-Host "No currently loaded ODBC connections."
    }
  }
  catch {
    return "Cannot disconnect $($Dsn): $($error[0].Exception.Message)"
  }
}

function Invoke-NoResultQuery {
  
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
  
  .Example
  $ExecuteStatement = "CREATE TABLE table_name (column1 datatype, column2 datatype,...);"
  NoResult-Query -Query $UpdateStatement
  
  If you run Connect-Database beforehand, you do not need to provide a DSN parameter.  Instead, this function will run against all currently connected databases.
  
  #>
  
  param(
    [Parameter(Position=0,Mandatory=1)]
    [string]$Query,
    [Parameter(Position=1,Mandatory=0)]
    [string]$Dsn=""
  )
  
  if(($Global:ODBCConnections | Measure).Count -lt 1){
    return "No database connections found.  Import a new connection using Connect-Database first."
  }
  
  $ConnectionsToUse = @()
  if($Dsn -eq "") {
    $ConnectionsToUse += $Global:ODBCConnections
  } else {
    $ConnectionsToUse += $Global:ODBCConnections | Where ConnectionString -eq ("DSN=" + $Dsn)
    if(($ConnectionsToUse | Measure).Count -lt 1){
      return "No currently loaded database connections matched $($Dsn)."
    }
  }
  
  foreach ($db in $ConnectionsToUse) {
    
    try {
    
    $cmd = $db.createCommand()
    $db.Open()
    $cmd.commandText = $Query
    $reader = $cmd.ExecuteReader()
    Write-Host "Query completed successfully!"
    
    } catch [Exception] {
      Write-Host "Caught the following exception:"
      Write-Host $_
      $_ | Select *
    } finally {
      if($reader) { $reader.Close() }
      $db.Close()
    }
  }
}

function Invoke-ResultQuery {
  
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
  
  If you currently have a connected database, you do not need the DSN parameter.
  
  #>
  
  param(
    [Parameter(Position=0,Mandatory=1)]
    [string]$Query,
    [Parameter(Position=1,Mandatory=0)]
    [string]$Dsn=""
  )
  
  if(($Global:ODBCConnections | Measure).Count -lt 1){
    return "No database connections found.  Import a new connection using Connect-Database first."
  }
  
  $ConnectionsToUse = @()
  if($Dsn -eq "") {
    $ConnectionsToUse += $Global:ODBCConnections
  } else {
    $ConnectionsToUse += $Global:ODBCConnections | Where ConnectionString -eq ("DSN=" + $Dsn)
    if(($ConnectionsToUse | Measure).Count -lt 1){
      return "No currently loaded database connections matched $($Dsn)."
    }
  }
  
  foreach ($db in $ConnectionsToUse) {
    
    try {
    
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
      if ($out.Count -ne 0) {
        return $out
      } else {
        return @()
      }
    } catch [Exception] {
      Write-Host "Caught the following exception:"
      Write-Host $_
      $_ | Select *
    } finally {
      $reader.Close()
      $db.Close()
    }
  }
  
}

function Get-ODBCConnections {
  
  if(($Global:ODBCConnections | Measure).Count -lt 1) {
    return "No databases currently connected."
  } else {
    return $Global:ODBCConnections
  }
}

function New-Migration {
  
  param(
    [Parameter(Position=0,Mandatory=0)]
    [string]$Query="",
    [Parameter(Position=1,Mandatory=0)]
    [string]$DownQuery="",
    [Parameter(Position=2,Mandatory=0)]
    [string]$Path=".",
    [Parameter(Position=3,Mandatory=0)]
    [string]$PreUp="",
    [Parameter(Position=4,Mandatory=0)]
    [string]$PostUp="",
    [Parameter(Position=5,Mandatory=0)]
    [string]$PreDown="",
    [Parameter(Position=6,Mandatory=0)]
    [string]$PostDown=""
  )
  
  #Establish template variables
  $Date = Get-Date -Format "yyyyddMMHHmmss"
  $Qualifier = "#="
  $PreQueryUp = ($Qualifier + "pre_query_up")
  $QueryUp = ($Qualifier + "query_up")
  $PostQueryUp = ($Qualifier + "post_query_up")
  $PreQueryDown = ($Qualifier + "pre_query_down")
  $QueryDown = ($Qualifier + "query_down")
  $PostQueryDown = ($Qualifier + "post_query_down")
  
  #Add SQL qualifiers
  if(!$Query.EndsWith(";") -AND $Query -ne "") {
    $Query += ";"
  }
  if(!$DownQuery.EndsWith(";") -AND $DownQuery -ne "") {
    $DownQuery += ";"
  }
  
  #Import migration template
  $temp = gc ".\Templates\migration_template.ps1"
  
  $temp = $temp -replace $PreQueryUp, $PreUp
  $temp = $temp -replace $PostQueryUp, $PostUp
  $temp = $temp -replace $PreQueryDown, $PreDown
  $temp = $temp -replace $PostQueryDown, $PostDown
  $temp = $temp -replace $QueryUp, ('"' + $Query + '"')
  $temp = $temp -replace $QueryDown, ('"' + $DownQuery + '"')
  
  $temp | Out-File "$($Path)\$($Date)_migration.ps1"
}

Export-ModuleMember Connect-ODBC, Disconnect-ODBC, Invoke-NoResultQuery, Invoke-ResultQuery, Get-ODBCConnections, New-Migration 
Export-ModuleMember -Variable ODBCConnections
