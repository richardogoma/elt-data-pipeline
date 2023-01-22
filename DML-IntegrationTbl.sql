-- ================Integration phase
SELECT COUNT(1) [NewRowsCount] FROM [dbo].[temp_$(TableName)] t
WHERE NOT EXISTS (
SELECT 1 FROM [dbo].[$(TableName)] p
WHERE p.$(PrimaryKey) = t.$(PrimaryKey) );
GO

INSERT INTO [dbo].[$(TableName)]
SELECT * FROM [dbo].[temp_$(TableName)] t
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[$(TableName)] p
    WHERE p.$(PrimaryKey) = t.$(PrimaryKey) )
ORDER BY t.$(PrimaryKey) ASC;
GO

DROP TABLE [dbo].[temp_$(TableName)];
GO