-- ================Integration phase
SELECT COUNT(1) [NewRowsCount] FROM [dbo].[temp_$(TableName)] t
WHERE NOT EXISTS (
SELECT 1 FROM [dbo].[prod_$(TableName)] p
WHERE p.JURISDICTIONNAME = t.JURISDICTIONNAME );
GO

INSERT INTO [dbo].[prod_$(TableName)]
SELECT * FROM [dbo].[temp_$(TableName)] t
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[prod_$(TableName)] p
    WHERE p.JURISDICTIONNAME = t.JURISDICTIONNAME )
ORDER BY t.JURISDICTIONNAME ASC;
GO

DROP TABLE [dbo].[temp_$(TableName)];
GO