CREATE PROCEDURE [spAoCSetup]
    @year INT,
    @day INT,
    @columnDefinitions NVARCHAR(MAX),
    @fieldTerminator NVARCHAR(12) = '\t',
    @rowTerminator NVARCHAR(12) = '\n'
AS
BEGIN
    DECLARE @filePath NVARCHAR(255) = CONCAT('/var/opt/mssql/aoc/', @year, '/day', RIGHT(CONCAT('0', @day), 2), '/input.txt'),
            @tableName NVARCHAR(128) = CONCAT('Day', RIGHT(CONCAT('0', @day), 2));

    IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = @tableName
    )
    BEGIN
        DECLARE @createTableCommand NVARCHAR(MAX) = N'
            CREATE TABLE ' + QUOTENAME(@tableName) + ' (' + @columnDefinitions + ')';

        EXECUTE [sys].[sp_executesql] @createTableCommand;
    END

    DECLARE @bulkInsertCommand NVARCHAR(MAX) = N'
        BULK INSERT ' + QUOTENAME(@tableName) + '
        FROM ''' + @filePath + '''
        WITH (
            FIELDTERMINATOR = ''' + @fieldTerminator + ''',
            ROWTERMINATOR = ''' + @rowTerminator + ''',
            FIRSTROW = 1,
            TABLOCK
        );';

    EXECUTE [sys].[sp_executesql] @bulkInsertCommand;
END;
