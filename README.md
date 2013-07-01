PowerRecord
===========
PowerRecord serves as a library of frequently used database functions.  It is currently a work-in-progress.

PowerRecord Examples
--------------------
First, add a new data source using the ODBC Data Source Administrator.  Second, add the PowerRecord module and submit the new Data Source Name (DSN) to the Connect-Database cmdlet.

```powershell
Import-Module PowerRecord.psm1
Connect-Database -Dsn "ODBC-ConnectionName"
```

Next, you can submit raw queries via the NoResult-Query and Result-Query cmdlets.

NoResult-Query Example:

```powershell
$InsertStatement = "INSERT INTO table_name (column1,column2,column3,...) VALUES (value1,value2,value3,...);"
NoResult-Query -Dsn "ODBC-Datasource" -Query $InsertStatement
```

Result-Query Example:

```powershell
$SelectStatement = "SELECT column_name,column_name FROM table_name;"
$result = Result-Query -Dsn "ODBC-Datasource" -Query $SelectStatement
if(($result | Measure).Count -lt 1) {
  return "Query returned no results."
} else {
  return $result | ft -auto
}
```

Future Features
---------------
DB Migrations - Currently, the example_migration.ps1 script shows the way to implement some basic DB migrations.