# Extract Load & Transform Process Development
## Problem Statement
Why build an ELT process? Well, I had a new task at work: _to extend the data pipeline I had recently built._ The program I built used a REST API to extract data and stored them in a remote central repository as flat files (.csv).

The new task was to extend the program to store the data in a local SQL Server database, so there was a new target repository. Plus the program had to integrate _only new data_ from the flat files into the database, that is, `incremental data processing`, and transform this data in some way for downstream usage. 

This has to be done with a particular focus on efficiency, reliability and scalability.

## Strategy
I did some research and figured out an efficient approach was to: 
1. Drop and create a temporary loading table in the staging area,
2. Load data from the source (the flat files) into this loading table using a _loading method_,
3. Transform and integrate only new data in the loading table into the integration table.
4. Drop the loading table once the integration phase has completed.

> A Data Staging Area is a design concept for a **Data Pipeline**. It is a location where raw/unprocessed data is stored before being modified for downstream usage. Database tables, files in a Cloud Storage System, and other staging regions are examples.

## Challenges
During development, one key problem was **dynamically loading CSV Imports into the staging area** with Powershell. The program had to intelligently figure out the column layouts and do some preprocessing. You can't have spaces between database field names, and some CSV files have special delimiters to prevent SQL injection attacks. 

The other problem was **choosing the most efficient loading method.**
> When working with a flat file as a source, you may want to use a strategy that leverages the most efficient loading utility available for the staging area technology. Most RDBMSs have fast loading utilities to load flat files into tables, such as Oracle's SQL*Loader, [`Microsoft SQL Server bcp`](https://learn.microsoft.com/en-us/sql/tools/bcp-utility?view=sql-server-ver16), Teradata FastLoad or MultiLoad. 

So I decided to use Microsoft SQL Server bulk copy program (bcp) to load the source file into the staging area, and all transformations will take place in the staging area afterwards.

## Process Description
The program once triggered, executes in the following sequence of steps:
1. Drop and create the loading table in the staging area
2. Execute the command to call the loading utility (bcp) to load the file to the loading table. 
3. Trigger the integration of the new data from the staging area into the integration table
4. Write to log files produced by the utility for error handling.
5. Drop the loading table once the integration phase has completed.

It should be noted that the copy speed of the loading utilty is machine dependent, but it is typically fast. I observed speeds of 15,000+ rows per sec on my local machine.

Also further transformation of the data is done on the SQL database (the staging area) which is typically efficient for processing large volumes of data. 