CREATE PROCEDURE [spAoCSetup]
    @year INT,
    @day INT,
    @columnDefinitions NVARCHAR(MAX),
    @rowTerminator NVARCHAR(12) = '\n'
AS
BEGIN
    BEGIN TRY
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

            PRINT 'Table created: ' + @tableName;
        END

        DECLARE @RAWDATA TABLE (
            [Id] INT IDENTITY(1,1),
            [Content] NVARCHAR(MAX)
        );

        DECLARE @bulkInsertCommand NVARCHAR(MAX) = N'
            BULK INSERT @RAWDATA
            FROM ''' + @filePath + '''
            WITH (
                FIELDTERMINATOR = ''' + @rowTerminator + ''',
                ROWTERMINATOR = ''' + @rowTerminator + ''',
                FIRSTROW = 1,
                TABLOCK
            );';

        EXECUTE [sys].[sp_executesql] @bulkInsertCommand;

        PRINT 'Data is imported from: ' + @filePath;
    END TRY

    BEGIN CATCH
        PRINT 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;
