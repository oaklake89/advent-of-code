WITH
    [Left]
    AS
    (
        SELECT
            [Column1], ROW_NUMBER() OVER (ORDER BY [Column1] ASC) AS [RowNum]
        FROM
            [Day01]
    ),
    [Right]
    AS
    (
        SELECT
            [Column2], ROW_NUMBER() OVER (ORDER BY [Column2] ASC) AS [RowNum]
        FROM
            [Day01]
    )

SELECT
    SUM(ABS([Left].[Column1] - [Right].[Column2])) AS [Sum]
FROM
    [Left]
INNER JOIN [Right] ON [Right].[RowNum] = [Left].[RowNum];
