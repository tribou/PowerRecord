PowerRecord
===========
PowerRecord serves as a library of frequently used database functions.  It is currently a work-in-progress.

PowerRecord Examples
--------------------
First, add a new data source using the ODBC Data Source Administrator.  Second, add the PowerRecord module and submit the new Data Source Name (DSN) to the Connect-Database cmdlet.

```powershell
Import-Module .\PowerRecord.psm1
Connect-ODBC "ODBC-ConnectionName"
```

Next, you can submit raw queries via the NoResult-Query and Result-Query cmdlets.

Invoke-NoResultQuery Example:

```powershell
$InsertStatement = "INSERT INTO table_name (column1,column2,column3,...) VALUES (value1,value2,value3,...);"
Invoke-NoResultQuery -Dsn "ODBC-Datasource" -Query $InsertStatement

# Or

Invoke-NoResultQuery $InsertStatement
```

Invoke-ResultQuery Example:

```powershell
$SelectStatement = "SELECT column_name,column_name FROM table_name;"
$result = Invoke-ResultQuery -Dsn "ODBC-Datasource" -Query $SelectStatement
if(($result | Measure).Count -lt 1) {
  return "Query returned no results."
} else {
  return $result | ft -auto
}
```

Show Current Connections:

```powershell
Get-ODBCConnections
```

Future Features
---------------
DB Migrations - Currently, the example_migration.ps1 script shows the way to implement some basic DB migrations.  Hopefully, future migrations can function something like the following:

```powershell
New-Migration "migration_description" "string:name" "string:description" "datetime:due_date"
```
