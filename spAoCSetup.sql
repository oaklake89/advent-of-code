CREATE OR ALTER PROCEDURE [spAoCSetup]
    @year INT,
    @day INT,
    @terminator NVARCHAR(12) = '\n'
AS
BEGIN
    BEGIN TRY
        DECLARE @filePath NVARCHAR(255) = CONCAT('/var/opt/mssql/aoc/', @year, '/day', RIGHT(CONCAT('0', @day), 2), '/input.txt'),
                @tableName NVARCHAR(128) = CONCAT('Day', RIGHT(CONCAT('0', @day), 2));

        -- Temp table
        IF OBJECT_ID('tempdb..#tblRawData') IS NOT NULL DROP TABLE #tblRawData;

        CREATE TABLE #tblRawData ([RowContent] NVARCHAR(MAX));

        -- BULK INSERT Command
        DECLARE @bulkInsertCommand NVARCHAR(MAX) = N'
            BULK INSERT #tblRawData
            FROM ''' + @filePath + '''
            WITH (
                FIELDTERMINATOR = ''' + @terminator + ''',
                ROWTERMINATOR = ''' + @terminator + ''',
                FIRSTROW = 1,
                TABLOCK
            );';

        PRINT @bulkInsertCommand;

        EXECUTE [sys].[sp_executesql] @bulkInsertCommand;

        -- Get the first row and count the number of columns
        DECLARE @firstRow NVARCHAR(MAX);
        SELECT TOP 1 @firstRow = [RowContent] FROM #tblRawData;

        SET @firstRow = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@firstRow, CHAR(9), CHAR(32)), CHAR(32) + CHAR(32), CHAR(32)), CHAR(32) + CHAR(32), CHAR(32))));

        DECLARE @columnCount INT = (LEN(@firstRow) - LEN(REPLACE(@firstRow, CHAR(32), ''))) + 1;
        PRINT 'Number of columns: ' + CAST(@columnCount AS NVARCHAR);

        -- Define Columns
        DECLARE @columnDefinitions NVARCHAR(MAX) = '';
        DECLARE @i INT = 1;

        WHILE @i <= @columnCount
        BEGIN
            SET @columnDefinitions += CASE WHEN @i > 1 THEN ', ' ELSE '' END
                                   + 'Column' + CAST(@i AS NVARCHAR) + ' NVARCHAR(MAX)';

            SET @i += 1;
        END

        -- Create the target table if it does not already exist
        IF NOT EXISTS (
            SELECT 1
            FROM [INFORMATION_SCHEMA].[TABLES]
            WHERE [TABLE_NAME] = @tableName
        )
        BEGIN
            DECLARE @createTableCommand NVARCHAR(MAX) = N'
                CREATE TABLE ' + QUOTENAME(@tableName) + ' (' + @columnDefinitions + ')';

            PRINT @createTableCommand;

            EXECUTE [sys].[sp_executesql] @createTableCommand;

            PRINT 'Table created: ' + @tableName;
        END

        -- Transform raw data into the target table
        DECLARE @insertCommand NVARCHAR(MAX) = N'
            INSERT INTO ' + QUOTENAME(@tableName) + '
            SELECT ';

        SET @i = 1;
        WHILE @i <= @columnCount
        BEGIN
            SET @insertCommand += CASE WHEN @i > 1 THEN ', ' ELSE '' END
                               + 'LTRIM(RTRIM(SUBSTRING([RowContent], '
                               + 'CASE WHEN ' + CAST(@i AS NVARCHAR) + ' = 1 THEN 1 ELSE CHARINDEX('' '', [RowContent] + '' '', CHARINDEX('' '', [RowContent] + '' '', ' + CAST(@i - 1 AS NVARCHAR) + ') + 1) + 1 END, '
                               + 'CASE WHEN ' + CAST(@i AS NVARCHAR) + ' = ' + CAST(@columnCount AS NVARCHAR) + ' THEN LEN([RowContent]) '
                               + 'ELSE CHARINDEX('' '', [RowContent] + '' '', CHARINDEX('' '', [RowContent] + '' '', ' + CAST(@i AS NVARCHAR) + ') + 1) - '
                               + 'CASE WHEN ' + CAST(@i AS NVARCHAR) + ' = 1 THEN 0 ELSE CHARINDEX('' '', [RowContent] + '' '', CHARINDEX('' '', [RowContent] + '' '', ' + CAST(@i - 1 AS NVARCHAR) + ') + 1) END - 1 END))) AS [' + 'Column' + CAST(@i AS NVARCHAR) + ']';

            SET @i += 1;
        END

        SET @insertCommand += ' FROM #tblRawData';

        PRINT @insertCommand;

        EXECUTE [sys].[sp_executesql] @insertCommand;

        PRINT 'Data inserted to: ' + @tableName;

        DROP TABLE #tblRawData;
    END TRY

    BEGIN CATCH
        IF OBJECT_ID('tempdb..#tblRawData') IS NOT NULL DROP TABLE #tblRawData;

        PRINT 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;
