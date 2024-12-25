WITH
    [Frequency]
    AS
    (
        SELECT
            [L].[Column1],
            COUNT([R].[Column2]) AS [Count]
        FROM
            [Day01] AS [L]
            LEFT JOIN [Day01] AS [R] ON [L].[Column1] = [R].[Column2]
        GROUP BY
            [L].[Column1]
    )

SELECT
    SUM([Frequency].[Column1] * [Frequency].[Count]) AS [Sum]
FROM
    [Frequency];