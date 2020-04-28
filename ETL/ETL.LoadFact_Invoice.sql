set ansi_nulls on;
go
set quoted_identifier on;
go

drop procedure if exists ETL.LoadFact_Invoice;
go

/*
==========================================================================================================
Author:			Brian Boswick
Create date:	04/24/2020
Description:	Creates the LoadFact_Invoice stored procedure
Changes
Developer		Date		Change
----------------------------------------------------------------------------------------------------------
==========================================================================================================	
*/

create procedure ETL.LoadFact_Invoice
as
begin
	set nocount on;

	declare	@ErrorMsg		varchar(1000);

	-- Clear Staging table
	if object_id(N'Staging.Fact_Invoice', 'U') is not null
		truncate table Staging.Fact_Invoice;

	begin try
		with MaxProducts	(
								PostFixtureAlternateKey,
								ProductAlternateKey,
								PortAlternateKey,
								LoadDischarge,
								Qty
							)
		as
		(
			select
				distinct
					parcel.RelatedSpiFixtureId			PostFixtureAlternateKey,
					max(product.RelatedProductId)		ProductAlternateKey,
					max(pp.RelatedPortId)				PortAlternateKey,
					pp.[Type]							LoadDischarge,
					parcel.BLQty						Qty
				from
					Parcels parcel with (nolock)
						join	(
									select
											p.RelatedSpiFixtureId,
											max(p.BLQty) BLQty
										from
											Parcels p with (nolock)
												join ParcelBerths pb
													on pb.QBRecId = p.RelatedLoadBerth
										group by
											p.RelatedSpiFixtureId
								) maxqty
							on maxqty.RelatedSpiFixtureId = parcel.RelatedSpiFixtureId
								and maxqty.BLQty = parcel.BLQty
						join ParcelBerths pb with (nolock)
							on parcel.RelatedLoadBerth = pb.QBRecId
						join ParcelPorts pp with (nolock)
							on pb.RelatedLDPId = pp.QBRecId
						join ParcelProducts product
							on product.QBRecId = parcel.RelatedParcelProductId
				group by
					parcel.RelatedSpiFixtureId,
					pp.[Type],
					parcel.BLQty
			union
			select
				distinct
					parcel.RelatedSpiFixtureId			PostFixtureAlternateKey,
					max(product.RelatedProductId)		ProductAlternateKey,
					max(pp.RelatedPortId)				PortAlternateKey,
					pp.[Type]							LoadDischarge,
					parcel.BLQty						Qty
				from
					Parcels parcel with (nolock)
						join	(
									select
											p.RelatedSpiFixtureId,
											max(p.BLQty) BLQty
										from
											Parcels p with (nolock)
												join ParcelBerths pb
													on pb.QBRecId = p.RelatedDischBerth
										group by
											p.RelatedSpiFixtureId
								) maxqty
							on maxqty.RelatedSpiFixtureId = parcel.RelatedSpiFixtureId
								and maxqty.BLQty = parcel.BLQty
						join ParcelBerths pb with (nolock)
							on parcel.RelatedDischBerth = pb.QBRecId
						join ParcelPorts pp with (nolock)
							on pb.RelatedLDPId = pp.QBRecId
						join ParcelProducts product
							on product.QBRecId = parcel.RelatedParcelProductId
				group by
					parcel.RelatedSpiFixtureId,
					pp.[Type],
					parcel.BLQty
		)

		insert
				Staging.Fact_Invoice with (tablock)
		select
			distinct
				ir.RecordID											InvoiceAlternateKey,
				isnull(invdate.DateKey, 18991230)					InvoiceDateKey,
				isnull(invduedate.DateKey, 18991230)				InvoiceDueDateKey,
				isnull(pmtrecdate.DateKey, 18991230)				PaymentReceivedDateKey,
				isnull(pf.PostFixtureKey, -1)						PostFixtureKey,
				isnull(loadport.PortKey, -1)						LoadPortKey,
				isnull(dischport.PortKey, -1)						DischargePortKey,
				isnull(product.ProductKey, -1)						ProductKey,
				-1													OwnerKey,
				-1													ChartererKey,
				--isnull(own.OwnerKey, -1)							OwnerKey,
				--isnull(wch.ChartererKey, -1)						ChartererKey,
				isnull(pq.ProductQuantityKey, -1)					ProductQuantityKey,
				isnull(cpdate.DateKey, 18991230)					CPDateKey,
				ir.InvoiceNumberOfficial_INVOICE					InvoiceNumber,
				ir.InvoiceType_ADMIN								InvoiceType,
				ir.InvoiceTo_INVOICE								InvoiceTo,
				ir.InvoiceStatus_ADMIN								InvoiceStatus,
				ir.VesselFormula_INVOICE							VesselFormula,
				ir.OfficeFormula_ADMIN								OfficeFormula,
				ir.BrokerFormula_ADMIN								BrokerFormula,
				ir.ChartererFormula_INVOICE							ChartererFormula,
				ir.OwnerFormula_INVOICE								OwnerFormula,
				ir.InvoiceGeneratedBy_ADMIN							InvoiceGeneratedBy,
				replace(ir.InvoiceAmountSnapShot_ADMIN, ',', '')	InvoiceAmount
			from
				InvoiceRegistry ir with (nolock)
					join Warehouse.Dim_PostFixture pf with (nolock)
						on pf.PostFixtureAlternateKey = ir.RelatedSPIFixtureID
					join PostFixtures epf with (nolock)
						on pf.PostFixtureAlternateKey = epf.QBRecId
					left join MaxProducts loadproduct with (nolock)
						on loadproduct.PostFixtureAlternateKey = ir.RelatedSPIFixtureID
							and loadproduct.LoadDischarge = 'Load'
					left join Warehouse.Dim_Port loadport with (nolock)
						on loadport.PortAlternateKey = loadproduct.PortAlternateKey
					left join MaxProducts dischproduct with (nolock)
						on dischproduct.PostFixtureAlternateKey = ir.RelatedSPIFixtureID
							and dischproduct.LoadDischarge = 'Discharge'
					left join Warehouse.Dim_Port dischport with (nolock)
						on dischport.PortAlternateKey = dischproduct.PortAlternateKey
					left join FullStyles cfs with (nolock)
						on epf.RelatedChartererFullStyle = cfs.QBRecId
					--left join FullStyles ofs with (nolock)
					--	on epf.RelatedOwnerFullStyle = ofs.QBRecId
					--left join Warehouse.Dim_Owner own with (nolock)
					--	on own.OwnerAlternateKey = cfs.RelatedOwnerParentId
					--left join Warehouse.Dim_Charterer wch with (nolock)
					--	on wch.ChartererAlternateKey = cfs.RelatedChartererParentID
					left join Warehouse.Dim_Calendar cpdate with (nolock)
						on cpdate.FullDate = convert(date, pf.CPDate)
					left join Warehouse.Dim_Calendar invdate with (nolock)
						on invdate.FullDate = convert(date, ir.InvoiceDateINVOICE)
					left join Warehouse.Dim_Calendar pmtrecdate with (nolock)
						on pmtrecdate.FullDate = convert(date, ir.DatePaymentReceived)
					left join Warehouse.Dim_Calendar invduedate with (nolock)
						on invduedate.FullDate = convert(date, ir.InvoiceDueDate)
					left join Warehouse.Dim_Product product with (nolock)
						on product.ProductAlternateKey = loadproduct.ProductAlternateKey
					left join Warehouse.Dim_ProductQuantity pq with (nolock)
						on loadproduct.Qty between pq.MinimumQuantity and pq.MaximumQuantity
	end try
	begin catch
		select @ErrorMsg = 'Staging Invoice records - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch	
	
	-- Clear Warehouse table
	if object_id(N'Warehouse.Fact_Invoice', 'U') is not null
		truncate table Warehouse.Fact_Invoice;

	-- Insert new events into Warehouse table
	begin try
		insert
				Warehouse.Fact_Invoice with (tablock)
			select
					inv.InvoiceAlternateKey,
					inv.InvoiceDateKey,
					inv.InvoiceDueDateKey,
					inv.PaymentReceivedDateKey,
					inv.PostFixtureKey,
					inv.LoadPortKey,
					inv.DischargePortKey,
					inv.ProductKey,
					inv.OwnerKey,
					inv.ChartererKey,
					inv.ProductQuantityKey,
					inv.CPDateKey,
					inv.InvoiceNumber,
					inv.InvoiceType,
					inv.InvoiceTo,
					inv.InvoiceStatus,
					inv.VesselFormula,
					inv.OfficeFormula,
					inv.BrokerFormula,
					inv.ChartererFormula,
					inv.OwnerFormula,
					inv.InvoiceGeneratedBy,
					inv.InvoiceAmount,
					getdate() RowStartDate
				from
					Staging.Fact_Invoice inv;
	end try
	begin catch
		select @ErrorMsg = 'Loading Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch
end