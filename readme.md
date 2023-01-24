# Readme
## What does this project do?

This is a program built using PowerShell and TSQL, and it is capable of loading source data dynamically into a staging area. The source data format used for development was comma delimited or `.csv`, and the program was designed to intelligently figure out the column layouts and do some pre-processing or cleanup of the data headers which were also used to create database tables. 

The staging area is a local temporary database table created automatically in the loading phase, and this is the location where raw/unprocessed data is stored before being modified for downstream usage.

Downstream usage in this case refers to the transformation and the integration of the staged data into an integration table. 

> While the staging area is the target of the loading phase, the program further integrates the data by processing the data in the staging area incrementally and persisting only new data into a production table in the database.

The program assumes that the source data has already been extracted and is available on-premise. However, **the actual purpose of the program was to extend a data pipeline that I built to programmatically query an API endpoint to extract business data, and to integrate that data into a central repository to support the data management, analytics and BI systems.**

Refer to [the Wiki](https://github.com/richardogoma/ELT_Development/wiki) for additional documentation.

## Setup the program

To run this program, clone or download the latest release of this project on your local machine, and **update the `Param block` defaults in [ELTJobExecutor.ps1](https://github.com/richardogoma/ELT_Development/blob/main/ELTJobExecutor.ps1)**

```powershell
Param(
    [string]$InstanceName = 'Your-Database-Instance'
    ,[string]$Database = 'Your-Database'
    ,[string]$SourceFile = '.\The-FilePath-To-Your.csv'
    ,[string]$SqlDataType = 'VARCHAR(MAX)'
    ,[string]$TableName = 'Your-Database-Table-Name'
    ,[string]$cwd
    ,[string]$PrimaryKey = 'Your-Database-Table-Primary-Key'
)
```
You might need to create a local database, and pass the `Instance Name` and `Database Name` as defaults to the `Param block`. 

## Source Data Constraints
* The source data has to be in `.csv` file format. This is a commonly used file format; it's non-binary and a flat file.
* The primary key has to be _the first field in the source data._ This is a best practice.

    > The primary key should be the first field (or fields) in your table design. While most databases allow you to define primary keys on any field in your table, the common convention and what the next developer will expect, is the primary key field(s) coming first.

* The primary key has to _contain numeric datatype values in the source data._ While it is true that there could be some irregularity in the source data, like there could be some strings in the primary key column, it is best practise to use a numeric field as primary key.

    > Uniquely tagging a record can be done with a number (long integer). Text fields require more bytes than numeric fields, so using a number saves considerable space. Please refer to this article on [Primary Key Tips and Techniques](https://www.fmsinc.com/free/newtips/PrimaryKey.asp)

* The source data is loaded to the staging area as string datatype for all columns/fields. This is defined in the `Param` block as `,[string]$SqlDataType = 'VARCHAR(MAX)'`.


