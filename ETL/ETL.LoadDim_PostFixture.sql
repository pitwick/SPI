/*
==========================================================================================================
Author:			Brian Boswick
Create date:	12/28/2018
Description:	Creates the LoadDim_PostFixture stored procedure
Changes
Developer		Date		Change
----------------------------------------------------------------------------------------------------------
==========================================================================================================	
*/

set ansi_nulls on;
go
set quoted_identifier on;
go

drop procedure if exists ETL.LoadDim_PostFixture;
go

create procedure ETL.LoadDim_PostFixture
as
begin

	declare	@NewRecord		smallint = 1,
			@ExistingRecord smallint = 2,
			@Type1Change	smallint = 4,
			@ErrorMsg		varchar(1000);

	-- Clear Staging table
	if object_id(N'Staging.Dim_PostFixture', 'U') is not null
		truncate table Staging.Dim_PostFixture;

	begin try
		insert
				Staging.Dim_PostFixture
		select
			distinct
				fixture.QBRecId,
				fixture.RelatedBroker,
				fixture.RelatedOpsPrimary,
				fixture.RelatedOpsBackup,
				fixture.CPDate,
				fixture.CPForm,
				fixture.DemurrageRate,
				fixture.TimeBar,
				fixture.AddressCommissionPercent,
				fixture.BrokerCommissionPercent,
				fixture.LaytimeAllowedLoad,
				fixture.LaytimeAllowedDisch,
				fixture.ShincReversible,
				fixture.VesselNameSnap,
				fixture.DemurrageAmountAgreed,
				fixture.CharterInvoiced,
				fixture.PaymentType,
				fixture.FreightLumpSumEntry,
				fixture.DischFAC,
				fixture.LaytimeOption,
				fixture.OwnersRef,
				fixture.CharterersRef,
				fixture.CurrencyInvoice,
				fixture.CharteringPicSnap,
				fixture.OperationsPicSnap,
				fixture.BrokerCommDemurrage,
				fixture.AddCommDeadFreight,
				fixture.DemurrageClaimReceived,
				fixture.VoyageNumber,
				fixture.LaycanToBeAmended,
				fixture.LaycanCancellingAmended,
				fixture.LaycanCommencementAmended,
				fixture.CurrencyCP,
				fixture.FixtureStatus,
				fixture.LaytimeAllowedTotalLoad,
				fixture.LaytimeAllowedTotalDisch,
				fixture.FrtRatePmt,
				fixture.BrokerFrtComm,
				fixture.P2FixtureRefNum,
				fixture.VesselFixedOfficial,
				fixture.LaycanCommencementOriginal,
				0 Type1HashValue,
				isnull(rs.RecordStatus, @NewRecord) RecordStatus
			from
				PostFixtures fixture
					left join	(
									select
											@ExistingRecord RecordStatus,
											PostFixtureAlternateKey
										from
											Warehouse.Dim_PostFixture
								) rs
						on rs.PostFixtureAlternateKey = fixture.QBRecId;
	end try
	begin catch
		select @ErrorMsg = 'Staging PostFixture records - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch	

	-- Generate hash values for Type 1 changes. Only Type 1 SCDs
	begin try
		update
				Staging.Dim_PostFixture
			set
				-- Type 1 SCD
				Type1HashValue =	hashbytes	(
													'MD2',
													concat	(
																RelatedBroker,
																RelatedOpsPrimary,
																RelatedOpsBackup,
																convert(nvarchar(30), CPDate),
																CPForm,
																convert(nvarchar(30), DemurrageRate),
																convert(nvarchar(30), TimeBar),
																convert(nvarchar(30), AddressCommissionPercent),
																convert(nvarchar(30), BrokerCommissionPercent),
																convert(nvarchar(30), LaytimeAllowedLoad),
																convert(nvarchar(30), LaytimeAllowedDisch),
																ShincReversible,
																VesselNameSnap,
																convert(nvarchar(30), DemurrageAmountAgreed),
																CharterInvoiced,
																PaymentType,
																convert(nvarchar(30), FreightLumpSumEntry),
																DischargeFAC,
																LaytimeOption,
																OwnersReference,
																CharterersReference,
																CurrencyInvoice,
																CharteringPicSnap,
																OperationsPicSnap,
																BrokerCommDemurrage,
																AddCommDeadFreight,
																DemurrageClaimReceived,
																VoyageNumber,
																LaycanToBeAmended,
																LaycanCancellingAmended,
																LaycanCommencementAmended,
																CurrencyCP,
																FixtureStatus,
																convert(nvarchar(30), LaytimeAllowedTotalLoad),
																convert(nvarchar(30), LaytimeAllowedTotalDisch),
																convert(nvarchar(30), FrtRatePmt),
																convert(nvarchar(30), BrokerFrtComm),
																P2FixtureRefNum,
																VesselFixedOfficial,
																LaycanCommencementOriginal
															)
												);
		
		update
				Staging.Dim_PostFixture
			set
				RecordStatus += @Type1Change
			from
				Warehouse.Dim_PostFixture wpf
			where
				wpf.PostFixtureAlternateKey = Staging.Dim_PostFixture.PostFixtureAlternateKey
				and wpf.Type1HashValue <> Staging.Dim_PostFixture.Type1HashValue;
	end try
	begin catch
		select @ErrorMsg = 'Updating hash values - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch

	-- Insert new post fixtures into Warehouse table
	begin try
		insert
				Warehouse.Dim_PostFixture
			select
					fixture.PostFixtureAlternateKey,
					fixture.RelatedBroker,
					fixture.RelatedOpsPrimary,
					fixture.RelatedOpsBackup,
					fixture.CPDate,
					fixture.CPForm,
					fixture.DemurrageRate,
					fixture.TimeBar,
					fixture.AddressCommissionPercent,
					fixture.BrokerCommissionPercent,
					fixture.LaytimeAllowedLoad,
					fixture.LaytimeAllowedDisch,
					fixture.ShincReversible,
					fixture.VesselNameSnap,
					fixture.DemurrageAmountAgreed,
					fixture.CharterInvoiced,
					fixture.PaymentType,
					fixture.FreightLumpSumEntry,
					fixture.DischargeFAC,
					fixture.LaytimeOption,
					fixture.OwnersReference,
					fixture.CharterersReference,
					fixture.CurrencyInvoice,
					fixture.CharteringPicSnap,
					fixture.OperationsPicSnap,
					fixture.BrokerCommDemurrage,
					fixture.AddCommDeadFreight,
					fixture.DemurrageClaimReceived,
					fixture.VoyageNumber,
					fixture.LaycanToBeAmended,
					fixture.LaycanCancellingAmended,
					fixture.LaycanCommencementAmended,
					fixture.CurrencyCP,
					fixture.FixtureStatus,
					fixture.LaytimeAllowedTotalLoad,
					fixture.LaytimeAllowedTotalDisch,
					fixture.FrtRatePmt,
					fixture.BrokerFrtComm,
					fixture.P2FixtureRefNum,
					fixture.VesselFixedOfficial,
					fixture.LaycanCommencementOriginal,
					fixture.Type1HashValue,
					getdate() RowStartDate,
					getdate() RowUpdatedDate,
					'Y' IsCurrentRow
				from
					Staging.Dim_PostFixture fixture
				where
					fixture.RecordStatus & @NewRecord = @NewRecord;
	end try
	begin catch
		select @ErrorMsg = 'Loading Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch

	-- Update existing records that have changed
	begin try
		update
				Warehouse.Dim_PostFixture
			set
				RelatedBroker = fixture.RelatedBroker,
				RelatedOpsPrimary = fixture.RelatedOpsPrimary,
				RelatedOpsBackup = fixture.RelatedOpsBackup,
				CPDate = fixture.CPDate,
				CPForm = fixture.CPForm,
				DemurrageRate = fixture.DemurrageRate,
				TimeBar = fixture.TimeBar,
				AddressCommissionPercent = fixture.AddressCommissionPercent,
				BrokerCommissionPercent = fixture.BrokerCommissionPercent,
				LaytimeAllowedLoad = fixture.LaytimeAllowedLoad,
				LaytimeAllowedDisch = fixture.LaytimeAllowedDisch,
				ShincReversible = fixture.ShincReversible,
				VesselNameSnap = fixture.VesselNameSnap,
				DemurrageAmountAgreed = fixture.DemurrageAmountAgreed,
				CharterInvoiced = fixture.CharterInvoiced,
				PaymentType = fixture.PaymentType,
				FreightLumpSumEntry = fixture.FreightLumpSumEntry,
				DischargeFAC = fixture.DischargeFAC,
				LaytimeOption = fixture.LaytimeOption,
				OwnersReference = fixture.OwnersReference,
				CharterersReference = fixture.CharterersReference,
				CurrencyInvoice = fixture.CurrencyInvoice,
				CharteringPicSnap = fixture.CharteringPicSnap,
				OperationsPicSnap = fixture.OperationsPicSnap,
				BrokerCommDemurrage = fixture.BrokerCommDemurrage,
				AddCommDeadFreight = fixture.AddCommDeadFreight,
				DemurrageClaimReceived = fixture.DemurrageClaimReceived,
				VoyageNumber = fixture.VoyageNumber,
				LaycanToBeAmended = fixture.LaycanToBeAmended,
				LaycanCancellingAmended = fixture.LaycanCancellingAmended,
				LaycanCommencementAmended = fixture.LaycanCommencementAmended,
				CurrencyCP = fixture.CurrencyCP,
				FixtureStatus = fixture.FixtureStatus,
				LaytimeAllowedTotalLoad = fixture.LaytimeAllowedTotalLoad,
				LaytimeAllowedTotalDisch = fixture.LaytimeAllowedTotalDisch,
				FrtRatePmt = fixture.FrtRatePmt,
				BrokerFrtComm = fixture.BrokerFrtComm,
				P2FixtureRefNum = fixture.P2FixtureRefNum,
				VesselFixedOfficial = fixture.VesselFixedOfficial,
				LaycanCommencementOriginal = fixture.LaycanCommencementOriginal,
				Type1HashValue = fixture.Type1HashValue,
				RowUpdatedDate = getdate()
			from
				Staging.Dim_PostFixture fixture
			where
				RecordStatus & @ExistingRecord = @ExistingRecord
				and fixture.PostFixtureAlternateKey = Warehouse.Dim_PostFixture.PostFixtureAlternateKey
				and RecordStatus & @Type1Change = @Type1Change;
	end try
	begin catch
		select @ErrorMsg = 'Updating existing records in Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch

	-- Insert Unknown record
	begin try
		if not exists (select 1 from Warehouse.Dim_PostFixture where PostFixtureKey = -1)
		begin
			set identity_insert Warehouse.Dim_PostFixture on;
			insert
					Warehouse.Dim_PostFixture	(
													PostFixtureKey,
													PostFixtureAlternateKey,
													RelatedBroker,
													RelatedOpsPrimary,
													RelatedOpsBackup,
													CPDate,
													CPForm,
													DemurrageRate,
													TimeBar,
													AddressCommissionPercent,
													BrokerCommissionPercent,
													LaytimeAllowedLoad,
													LaytimeAllowedDisch,
													ShincReversible,
													VesselNameSnap,
													DemurrageAmountAgreed,
													CharterInvoiced,
													PaymentType,
													FreightLumpSumEntry,
													DischargeFAC,
													LaytimeOption,
													OwnersReference,
													CharterersReference,
													CurrencyInvoice,
													CharteringPicSnap,
													OperationsPicSnap,
													BrokerCommDemurrage,
													AddCommDeadFreight,
													DemurrageClaimReceived,
													VoyageNumber,
													LaycanToBeAmended,
													LaycanCancellingAmended,
													LaycanCommencementAmended,
													CurrencyCP,
													FixtureStatus,
													LaytimeAllowedTotalLoad,
													LaytimeAllowedTotalDisch,
													FrtRatePmt,
													BrokerFrtComm,
													P2FixtureRefNum,
													VesselFixedOfficial,
													LaycanCommencementOriginal,
													Type1HashValue,
													RowCreatedDate,
													RowUpdatedDate,
													IsCurrentRow
												)

				values	(
							-1,				-- PostFixtureKey
							0,				-- PostFixtureAlternateKey
							'Unknown',		-- RelatedBroker
							'Unknown',		-- RelatedOpsPrimary
							'Unknown',		-- RelatedOpsBackup
							'12/30/1899',	-- CPDate
							'Unknown',		-- CPForm
							0.0,			-- DemurrageRate
							0.0,			-- TimeBar
							0.0,			-- AddressCommissionPercent
							0.0,			-- BrokerCommissionPercent
							0.0,			-- LaytimeAllowedLoad
							0.0,			-- LaytimeAllowedDisch
							'Unknown',		-- ShincReversible
							'Unknown',		-- VesselNameSnap
							0.0,			-- DemurrageAmountAgreed
							'U',			-- CharterInvoiced
							'Unknown',		-- PaymentType
							0.0,			-- FreightLumpSumEntry
							'U',			-- DischargeFAC
							'Unknown',		-- LaytimeOption
							'Unknown',		-- OwnersReference
							'Unknown',		-- CharterersReference
							'Unknown',		-- CurrencyInvoice
							'Unknown',		-- CharteringPicSnap
							'Unknown',		-- OperationsPicSnap
							'U',			-- BrokerCommDemurrage
							'U',			-- AddCommDeadFreight
							'12/30/1899',	-- DemurrageClaimReceived
							'Unknown',		-- VoyageNumber
							'U',			-- LaycanToBeAmended
							'12/30/1899',	-- LaycanCancellingAmended
							'12/30/1899',	-- LaycanCommencementAmended
							'Unknown',		-- CurrencyCP
							'Unknown',		-- FixtureStatus
							0.0,			-- LaytimeAllowedTotalLoad
							0.0,			-- LaytimeAllowedTotalDisch
							0.0,			-- FrtRatePmt
							0.0,			-- BrokerFrtComm
							'Unknown',		-- P2FixtureRefNum
							'Unknown',		-- VesselFixedOfficial
							'12/30/1899',	-- LaycanCommencementOriginal
							0,				-- Type1HashValue
							getdate(),		-- RowCreatedDate
							getdate(),		-- RowUpdatedDate
							'Y'				-- IsCurrentRow
						);
			set identity_insert Warehouse.Dim_PostFixture off;
		end
	end try
	begin catch
		select @ErrorMsg = 'Inserting Unknown record into Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch
end