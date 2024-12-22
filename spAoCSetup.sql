CREATE OR ALTER PROCEDURE [spAoCSetup]
    @year INT,
    @day INT,
    @rowTerminator NVARCHAR(12) = '\n'
AS
BEGIN
    BEGIN TRY
        DECLARE @filePath NVARCHAR(255) = CONCAT('/var/opt/mssql/aoc/', @year, '/day', RIGHT(CONCAT('0', @day), 2), '/input.txt'),
                @tableName NVARCHAR(128) = CONCAT('Day', RIGHT(CONCAT('0', @day), 2));

        IF OBJECT_ID('tempdb..#tblRawData') IS NOT NULL
            DROP TABLE #tblRawData;

        CREATE TABLE #tblRawData
        (
            [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            [Content] NVARCHAR(MAX)
        );

        DECLARE @bulkInsertCommand NVARCHAR(MAX) = N'
            BULK INSERT #tblRawData
            FROM ''' + @filePath + '''
            WITH (
                FIELDTERMINATOR = ''' + @rowTerminator + ''',
                ROWTERMINATOR = ''' + @rowTerminator + ''',
                FIRSTROW = 1,
                TABLOCK
            );';

        EXECUTE [sys].[sp_executesql] @bulkInsertCommand;

        DECLARE @firstRow NVARCHAR(MAX);
        SELECT TOP 1 @firstRow = [Content] FROM #tblRawData;

        DECLARE @columnCount INT = (LEN(@firstRow) - LEN(REPLACE(@firstRow, ' ', ''))) + 1;
        PRINT 'Number of columns: ' + CAST(@columnCount AS NVARCHAR);

        DECLARE @columnDefinitions NVARCHAR(MAX) = '';
        DECLARE @i INT = 1;

        WHILE @i <= @columnCount
        BEGIN
            SET @columnDefinitions += CASE WHEN @i > 1 THEN ', ' ELSE '' END
                                   + 'Column' + CAST(@i AS NVARCHAR) + ' NVARCHAR(MAX)';

            SET @i += 1;
        END

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

        DECLARE @insertCommand NVARCHAR(MAX) = N'
            INSERT INTO ''' + QUOTENAME(@tableName) + '''
            SELECT ';

        SET @i = 1;
        WHILE @i <= @columnCount
        BEGIN
            SET @insertCommand += CASE WHEN @i > 1 THEN ', ' ELSE '' END
                               + 'LTRIM(RTRIM(SUBSTRING(Content, '
                               + 'CHARINDEX('' '', Content + '' '', ' + CAST(@i AS NVARCHAR) + ') + 1, '
                               + 'CASE WHEN CHARINDEX('' '', Content + '' '', CHARINDEX('' '', Content + '' '', '
                               + CAST(@i AS NVARCHAR) + ') + 1) > 0 THEN '
                               + 'CHARINDEX('' '', Content + '' '', CHARINDEX('' '', Content + '' '', '
                               + CAST(@i AS NVARCHAR) + ') + 1) ELSE LEN(Content) + 1 END '
                               + '- CHARINDEX('' '', Content + '' '', ' + CAST(@i AS NVARCHAR) + ') - 1))) AS Column'
                               + CAST(@i AS NVARCHAR);

            SET @i += 1;
        END

        SET @insertCommand += ' FROM #tblRawData'

        EXECUTE [sys].[sp_executesql] @insertCommand;

        PRINT 'Data inserted to: ' + @tableName;

        DROP TABLE #tblRawData;
    END TRY

    BEGIN CATCH
        IF OBJECT_ID('tempdb..#tblRawData') IS NOT NULL
            DROP TABLE #tblRawData;

        PRINT 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;
