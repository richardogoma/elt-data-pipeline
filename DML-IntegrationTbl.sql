-- ================Integration phase
SELECT COUNT(1) [NewRowsCount] FROM [dbo].[temp_$(TableName)] t
WHERE NOT EXISTS (
SELECT 1 FROM [dbo].[prod_$(TableName)] p
WHERE p.$(PrimaryKey) = t.$(PrimaryKey) );
GO

INSERT INTO [dbo].[prod_$(TableName)]
SELECT * FROM [dbo].[temp_$(TableName)] t
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[prod_$(TableName)] p
    WHERE p.$(PrimaryKey) = t.$(PrimaryKey) )
ORDER BY t.$(PrimaryKey) ASC;
GO

DROP TABLE [dbo].[temp_$(TableName)];
GO