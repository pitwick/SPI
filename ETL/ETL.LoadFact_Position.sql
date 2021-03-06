set ansi_nulls on;
go
set quoted_identifier on;
go

drop procedure if exists ETL.LoadFact_Position;
go

/*
==========================================================================================================
Author:			Brian Boswick
Create date:	01/27/2020
Description:	Creates the LoadFact_Position stored procedure
Changes
Developer		Date		Change
----------------------------------------------------------------------------------------------------------
Brian Boswick	02/10/2020	Added OwnerKey ETL logic
Brian Boswick	02/12/2020	Added Direction and ShippingArea ETL logic
Brian Boswick	09/21/2020	Changed OwnerKey to OwnerParentKey and repointed to Dim_OwnerParent
==========================================================================================================	
*/

create procedure ETL.LoadFact_Position
as
begin
	set nocount on;

	declare	@ErrorMsg		varchar(1000),
			@NewRecord			int = 1,
			@ExistingRecord		int = 2;

	-- Clear Staging table
	if object_id(N'Staging.Fact_Position', 'U') is not null
		truncate table Staging.Fact_Position;

	begin try
		insert
				Staging.Fact_Position with (tablock)	(	
															PositionAlternateKey,
															ProductKey,
															PortKey,
															DischargePortKey,
															VesselKey,
															OpenDateKey,
															EndDateKey,
															OwnerParentKey,
															Comments,
															StatusCalculation,
															LastCargo,
															FOFSA,
															PositionType,
															Direction,
															ShippingArea
														)	
		select
				p.RecordID							PositionAlternateKey,
				isnull(prod.ProductKey, -1)			ProductKey,
				isnull(wport.PortKey, -1)			PortKey,
				isnull(dischport.PortKey, -2)		DischargePortKey,
				isnull(v.VesselKey, -1)				VesselKey,
				isnull(od.DateKey, -1)				OpenDateKey,
				isnull(ed.DateKey, -1)				EndDateKey,
				isnull(o.OwnerParentKey, -1)		OwnerParentKey,
				p.Comments							Comments,
				p.StatusCalculation_ADMIN			StatusCalculation,
				p.LastCargo							LastCargo,
				p.FOFSA_prod						FOFSA,
				p.PositionType						PositionType,
				p.Direction							Direction,
				sa.[Name]							ShippingArea
			from
				Positions p with (nolock)
					left join Warehouse.Dim_Calendar od with (nolock)
						on convert(date, p.DateOpen) = od.FullDate
					left join Warehouse.Dim_Calendar ed with (nolock)
						on convert(date, p.EndDate) = ed.FullDate
					left join Warehouse.Dim_Vessel v with (nolock)
						on v.VesselAlternateKey = p.RelatedVesselID
					left join Warehouse.Dim_Port wport with (nolock)
						on wport.PortAlternateKey = p.RelatedPortID
					left join Warehouse.Dim_Product prod with (nolock)
						on prod.ProductAlternateKey = p.RelatedProductID
					left join Warehouse.Dim_Port dischport with (nolock)
						on dischport.PortName = isnull(p.Direction, '')
					left join Warehouse.Dim_OwnerParent o with (nolock)
						on o.OwnerParentAlternateKey = p.RelatedOwnerParentID
					left join ShippingAreas sa with (nolock)
						on sa.QBRecId = p.RelatedShippingAreaID_P;
	end try
	begin catch
		select @ErrorMsg = 'Staging records - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch	
	
	-- Clear Warehouse table
	if object_id(N'Warehouse.Fact_Position', 'U') is not null
		truncate table Warehouse.Fact_Position;

	-- Insert records into Warehouse table
	begin try
		insert
				Warehouse.Fact_Position with (tablock)	(
															PositionAlternateKey,
															ProductKey,
															PortKey,
															DischargePortKey,
															VesselKey,
															OpenDateKey,
															EndDateKey,
															OwnerParentKey,
															Comments,
															StatusCalculation,
															LastCargo,
															FOFSA,
															PositionType,
															Direction,
															ShippingArea,
															RowCreatedDate
														)
			select
					sp.PositionAlternateKey,
					sp.ProductKey,
					sp.PortKey,
					sp.DischargePortKey,
					sp.VesselKey,
					sp.OpenDateKey,
					sp.EndDateKey,
					sp.OwnerParentKey,
					sp.Comments,
					sp.StatusCalculation,
					sp.LastCargo,
					sp.FOFSA,
					sp.PositionType,
					sp.Direction,
					sp.ShippingArea,
					getdate()
				from
					Staging.Fact_Position sp;
	end try
	begin catch
		select @ErrorMsg = 'Loading Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch
end