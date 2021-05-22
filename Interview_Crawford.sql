/*
1. Use "SET NOCOUNT ON"

2. Click on display estimated execution plan and live stats, then run query
   Make note of indexes and if possible create them - see below 

3. Potentially rewrite the SPs (specifically usp_GetLegacyActivityTimeline)
   - maybe making use of CTEs

*/

--usp_GetLegacyActivityTimeline

USE [Interview1]
GO
CREATE NONCLUSTERED INDEX [NCL_PartyClaimRole_ClaimRef]
ON [dbo].[PartyClaimRole] ([ClaimReference])

GO

USE [Interview1]
GO
CREATE NONCLUSTERED INDEX [NCL_LegAct_ClaimRef_TC]
ON [dbo].[LegacyActivities] ([ClaimReference],[TypeCode])

GO


--usp_GetActivityEnrichments
USE [Interview1]
GO
CREATE NONCLUSTERED INDEX [NCL_LegActivityID_Party]
ON [dbo].[Activities] ([LegacyActivityId])
INCLUDE ([Id],[PartyId],[PartyType])
GO

USE [Interview1]
GO
CREATE NONCLUSTERED INDEX [LegacyActivity_FileActivity]
ON [dbo].[FileActivityLinks] ([LegacyActivityId])
INCLUDE ([Id])
GO
