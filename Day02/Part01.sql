WITH
    [Recursive]
    AS
    (
        SELECT
            [Id],
            CAST(LEFT([Column1], CHARINDEX(' ', [Column1] + ' ')-1) AS INT) AS [Value],
            CAST(STUFF([Column1], 1, CHARINDEX(' ', [Column1] + ' '), '') AS NVARCHAR(MAX)) AS [Remainder],
            1 AS [Position]
        FROM
            [Day02]

        UNION ALL

        SELECT
            [Id],
            CAST(LEFT([Remainder], CHARINDEX(' ', [Remainder] + ' ')-1) AS INT),
            CAST(STUFF([Remainder], 1, CHARINDEX(' ', [Remainder] + ' '), '') AS NVARCHAR(MAX)),
            [Position] + 1
        FROM
            [Recursive]
        WHERE
            [Remainder] <> ''
    ),
    [Separated]
    AS
    (
        SELECT
            [Id],
            [Position],
            [Value]
        FROM
            [Recursive]
    ),
    [Paired]
    AS
    (
        SELECT
            [S1].[Id],
            [S1].[Position] AS [Pos1],
            [S1].[Value] AS [Val1],
            [S2].[Position] AS [Pos2],
            [S2].[Value] AS [Val2],
            ([S2].[Value] - [S1].[Value]) AS [Diff]
        FROM
            [Separated] AS [S1]
        INNER JOIN [Separated] [S2] ON [S2].[Id] = [S1].[Id]
            AND [S2].[Position] = [S1].[Position] + 1
    ),
    [CheckPaired]
    AS
    (
        SELECT
            [Id],
            MIN([Diff]) AS [MinDiff],
            MAX([Diff]) AS [MaxDiff],
            MIN(ABS([Diff])) AS [MinAbsDiff],
            MAX(ABS([Diff])) AS [MaxAbsDiff]
        FROM
            [Paired]
        GROUP BY
            [Id]
    ),
    [Evaluated]
    AS
    (
        SELECT
            [Id],
            CASE
                WHEN
                    ([MinDiff] > 0 AND [MaxDiff] > 0)
                    AND ([MinAbsDiff] >= 1 AND [MaxAbsDiff] <= 3)
                THEN 1
                WHEN
                    ([MinDiff] < 0 AND [MaxDiff] < 0)
                    AND ([MinAbsDiff] >= 1 AND [MaxAbsDiff] <= 3)
                THEN 1
                ELSE 0
            END AS [IsSafe]
        FROM
            [CheckPaired]
    )

SELECT
    SUM([IsSafe]) AS [NumberOfSafeReports]
FROM
    [Evaluated];
