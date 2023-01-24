-- ================Staging data transformation
-- There is no field with primary key constraint in the loading table, this is a representation of the integration table design
DELETE FROM [dbo].[temp_$(TableName)]
WHERE $(PrimaryKey) LIKE '%[^0-9]%';

ALTER TABLE temp_$(TableName) ALTER COLUMN $(PrimaryKey) INT;

CREATE CLUSTERED INDEX $(PrimaryKey)_ASC ON temp_$(TableName) ($(PrimaryKey));
GO

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