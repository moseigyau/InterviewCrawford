ALTER PROCEDURE [dbo].[usp_GetLegacyActivityTimeline]
	@ClaimReference NVARCHAR(50)
	,@Filter NVARCHAR(MAX)
	,@Category NVARCHAR(50)
	,@Start DATETIME
	,@End DATETIME
	,@Skip INT
	,@Take INT
	,@SortDescending BIT
AS
BEGIN
     
	 WITH cte AS (
      SELECT
								[Id]
								,[ClaimReference]
								,[CategoryInd]
								,[TypeCode]
								,[AdhocOrPartyInd]
								,[PartyId]
								,[AdhocPartyId]
								,[ActivityDate]
								,[Detail]
								,[CompletedBy]
							
								FROM [dbo].[LegacyActivities]						
								WHERE 
									[ClaimReference] = @ClaimReference AND 
									(@Start IS NULL OR [ActivityDate] >= @Start) AND
									(@End IS NULL OR [ActivityDate] <= @End) AND
									[TypeCode] NOT IN ('TSKC')
		                ) 		

	SELECT
		[ClaimReference]
		,[LegacyActivityId]
		,[Category]
		,[Type]
		,[Completed]
		,[CompletedBy]
		,[Details]
		,[IsEmailPreviewAvailable]
		,[PartyType]
		FROM (
			SELECT
				[ClaimReference]
				,[LegacyActivityId]
				,[Category]
				,[Type]
				,[dbo].[fn_LocaltoUTC]([Completed]) AS [Completed]
				,[CompletedBy]
				,[Details]
				,[IsEmailPreviewAvailable]
				,[PartyType]
				,ROW_NUMBER() OVER (
					ORDER BY
						CASE WHEN @SortDescending = 0 THEN [Completed] END ASC,
						CASE WHEN @SortDescending = 1 THEN [Completed] END DESC	 ) AS RowNum
				FROM (
					SELECT
						[act].[ClaimReference]
						,[act].[Id] AS [LegacyActivityId]
						,CASE [act].[CategoryInd] 
							WHEN 'T' THEN 'Telephone'
							WHEN 'V' THEN 'Visit'
							WHEN 'A' THEN 'Appointment'
							WHEN 'E' THEN 'Email'
							WHEN 'C' THEN 'Correspondence'
							ELSE 'Other'
						END AS [Category]
						,[actType].[Description] AS [Type]
						,[act].[ActivityDate] AS [Completed]
						,[usr].[DisplayName] AS [CompletedBy]
						,COALESCE(em.BodyText, [act].[Detail])
						 AS [Details]
						,CASE 
							WHEN em.BodyText IS NULL THEN 0
							ELSE 1
						END AS [IsEmailPreviewAvailable],
						ISNULL(ISNULL([partyType].[description], [partyTypeEmail].[description]),'Unknown') AS [PartyType]
						FROM (
							SELECT
								[Id]
								,[ClaimReference]
								,[CategoryInd]
								,[TypeCode]
								,[AdhocOrPartyInd]
								,[PartyId]
								,[AdhocPartyId]
								,[ActivityDate]
								,[Detail]
								,[CompletedBy]
								FROM cte
								  --[dbo].[LegacyActivities]
								--WHERE 
								--	[ClaimReference] = @ClaimReference AND 
								--	(@Start IS NULL OR [ActivityDate] >= @Start) AND
								--	(@End IS NULL OR [ActivityDate] <= @End) AND
								--	[TypeCode] NOT IN ('TSKC')
						) AS [act]
						INNER JOIN [dbo].[LegacyActivityTypes] [actType] ON [actType].[Code] = [act].[TypeCode]
						INNER JOIN [dbo].[LegacyActivityCategories] [actCat] ON [actCat].[Code] = [actType].[CategoryCode]
						LEFT JOIN [dbo].[Users] [usr] ON [usr].[UserId] = [act].[CompletedBy] 
						LEFT JOIN [dbo].[Email] [em] ON [em].[LegacyActivityId] = [act].[Id]
						LEFT JOIN [dbo].[PartyClaimRole] [p] ON [p].[ClaimReference] = [act].[ClaimReference] AND 
							([p].[PartyId] = [act].[PartyId] OR [p].[AdhocPartyId] = [act].[AdhocPartyId]
							)
						LEFT JOIN [dbo].[PartyTypes] [partyType] ON [partyType].[Code] = [p].[PartyTypeCode]
						LEFT JOIN [dbo].[PartyTypes] [partyTypeEmail] ON [partyTypeEmail].[Code] = [em].[PartyTypeCode]
				) AS [Data]
				WHERE 
					(@Filter IS NULL OR ([Category] LIKE '%' + @Filter + '%' OR   
										 [Type] LIKE '%' + @Filter + '%' OR  
										 [CompletedBy] LIKE '%' + @Filter + '%' OR 
										 [Details] LIKE '%' + @Filter + '%')) AND
					(@Category IS NULL OR [Category] = @Category)
		) AS [a]
		WHERE [RowNum] >  @Skip AND [RowNum] <= @Skip + @Take
		ORDER BY [RowNum]	
END

GO


