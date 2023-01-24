# What does this project do?

This PowerShell program is capable of loading source data dynamically into a staging area. The source data format used for development was comma delimited or `.csv`, and the program was designed to intelligently figure out the column layouts and do some pre-processing or cleanup of the data headers which were also used to create database tables. 

The staging area is a local temporary database table created automatically in the loading phase, and this is the location where raw/unprocessed data is stored before being modified for downstream usage.

Downstream usage in this case refers to the transformation or the integration of the staged data into an integration table. 

> While the staging area is the target of the loading phase, the program further integrates the data by processing the data in the staging area incrementally and persisting only new data into a production table in the database.

The program assumes that the source data has already been extracted and is available on-premise. However, **the actual purpose of the program was to extend a data pipeline that I built to programmatically invoke a REST API to extract business data from a SAAS application and to integrate the data into a central repository to support the data management, analytics and BI systems.**

Refer to [the Wiki](https://github.com/richardogoma/ELT_Development/wiki) for additional documentation.

# Setup the program

To run this program, clone or download the latest release of this project on your local machine, and **update the `Param block` defaults in [ELTJobExecutor.ps1](https://github.com/richardogoma/ELT_Development/blob/main/ELTJobExecutor.ps1)**

```powershell
Param(
    [string]$InstanceName = 'localhost'
    ,[string]$Database = 'NLNGProjects'
    ,[string]$SourceFile = '.\20230123-115724-8304473-requests-1.csv'
    ,[string]$SqlDataType = 'VARCHAR(MAX)'
    ,[string]$TableName = 'tblNLNGITRequests'
    ,[string]$PrimaryKey = 'ID'
)
```
You may also need to create a local database, and pass the `Instance Name` and `Database Name` as defaults to the `Param block`. 
