use [NLNGProjects];
go

-- ================Metadata
SELECT * FROM sys.tables 
WHERE name = 'prod_NYCDemographics' OR name = 'temp_NYCDemographics';

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE 
FROM NLNGProjects.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'prod_NYCDemographics' OR TABLE_NAME = 'temp_NYCDemographics';

SELECT * 
FROM NLNGProjects.INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'prod_NYCDemographics' OR TABLE_NAME = 'temp_NYCDemographics';

SELECT * 
FROM NLNGProjects.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
WHERE TABLE_NAME = 'prod_NYCDemographics' OR TABLE_NAME = 'temp_NYCDemographics';

SELECT t.CONSTRAINT_TYPE, c.COLUMN_NAME
FROM NLNGProjects.INFORMATION_SCHEMA.TABLE_CONSTRAINTS t
	JOIN NLNGProjects.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE c
		ON t.CONSTRAINT_NAME = c.CONSTRAINT_NAME
WHERE t.CONSTRAINT_TYPE = 'PRIMARY KEY'
	AND t.TABLE_NAME = 'temp_NYCDemographics'
GO

-- ================Integration phase
SELECT COUNT(1) [NewRowsCount] FROM [dbo].[temp_NYCDemographics] t
WHERE NOT EXISTS (
	SELECT 1 FROM [dbo].[prod_NYCDemographics] p
	WHERE p.JURISDICTIONNAME = t.JURISDICTIONNAME );

INSERT INTO [dbo].[prod_NYCDemographics]
SELECT * FROM [dbo].[temp_NYCDemographics] t
WHERE NOT EXISTS (
	SELECT 1 FROM [dbo].[prod_NYCDemographics] p
	WHERE p.JURISDICTIONNAME = t.JURISDICTIONNAME )
ORDER BY t.JURISDICTIONNAME ASC;
GO

SELECT * FROM [dbo].[prod_NYCDemographics];
SELECT * FROM [dbo].[temp_NYCDemographics]
GO

DROP TABLE [dbo].[temp_NYCDemographics];
drop table [dbo].[prod_NYCDemographics]
go 








