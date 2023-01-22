# Extract Load & Transform Process Development
## Problem Statement
**Why build an ELT process?** Well, I had a new task at work: _to extend a data pipeline I had recently built._ The program I built used a REST API to extract data and stored them in a remote central repository as flat files (.csv).

The new task was to extend the program to store the data in a local SQL Server database, and so there was a new target repository. Plus the program had to integrate _only new data_ from the flat files into the database-- `incrementally process the data`, and transform this data in some way for downstream usage. 

This has to be done with a particular focus on efficiency, reliability and scalability.

## Strategy
I did some research and figured out an efficient approach was to: 
1. Create a temporary loading table in a _staging area,_
2. Load data from the source (the flat files) into this loading table using a _loading method,_
3. Transform and integrate only new data in the loading table into an integration table,
4. Drop the loading table once the integration phase has completed.

> A Data Staging Area is a design concept for a **Data Pipeline**. It is a location where raw/unprocessed data is stored before being modified for downstream usage. Database tables, files in a Cloud Storage System, and other staging regions are examples.

## Challenges
During development, one key problem was **dynamically loading the flat files into the staging area** with Powershell. The program had to intelligently figure out the column layouts and do some pre-processing. You can't have spaces between database field names, and some CSV files have special delimiters to prevent SQL injection attacks. 

The other problem was **choosing the most efficient loading method.**
> When working with a flat file as a source, you may want to use a strategy that leverages the most efficient loading utility available for the staging area technology. Most RDBMSs have fast loading utilities to load flat files into tables, such as Oracle's SQL*Loader, [`Microsoft SQL Server bcp`](https://learn.microsoft.com/en-us/sql/tools/bcp-utility?view=sql-server-ver16), Teradata FastLoad or MultiLoad. 

So I decided to use Microsoft SQL Server bulk copy program (bcp) to load the source file into the staging area, and all transformations will take place in the staging area afterwards.

> **Note:** It is possible to use the BCP (bulk copy program) utility to copy data from an input stream, such as the output from an `Invoke-WebRequest` command in PowerShell. You can redirect the output from `Invoke-WebRequest` to a file, and then use BCP to import the data from that file into a SQL Server table. It is also smart to use a background job to handle the file redirection (or download) task, and track its state before invoking the bcp utility. 

## Process Description
The program once triggered, executes in the following sequence of steps:
1. Drop _(if exists)_ and create a loading table in the staging area
2. Execute a command to call the loading utility (bcp) to load the file to the loading table. 

    > It should be noted that the copy speed of the loading utilty (bcp) is machine dependent, but it is efficient. I observed an average speed of `6,553.90 rows per sec. (RPS)` on my local machine; and it took a `total of 1.141secs to bulk copy 7,478 rows to SQL Server` on my local machine. 

3. Trigger the integration of the new data from the staging area into the integration table

    > A TSQL script is used for data integration, and in this case, for migrating new or updated data from a temporary table to a production table while avoiding duplicating existing rows in the production table. It is run via a PowerShell Script with the table name and primary key specified, and it is a part of the larger data integration process that would be automated to run periodically.

4. Write to log files produced by the utility for error handling.
5. Drop the loading table once the integration phase has completed.

    > In the integration phase, further (or downstream) transformation of the data would be performed in the SQL database (the staging area) which is typically efficient for processing large volumes of data.

## References
* [Loading Strategies](https://docs.oracle.com/middleware/1213/odi/develop-km/lkm.htm)
* [A Common Architecture for Loading Data](https://www.sqlservercentral.com/articles/a-common-architecture-for-loading-data)
* [Write PowerShell output to a SQL Server table](https://www.sqlshack.com/6-methods-write-powershell-output-sql-server-table/)
* [Dynamic CSV Imports with #Powershell](https://www.mikefal.net/2016/03/09/dynamic-csv-imports-with-powershell/)
* [What is a Data Staging Area?](https://hevodata.com/learn/data-staging-area/)
* [SQL Optimization - Indexing](https://dataschool.com/sql-optimization/how-indexing-works/)