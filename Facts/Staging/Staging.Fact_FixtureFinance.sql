/*
==========================================================================================================
Author:			Brian Boswick
Create date:	02/22/2019
Description:	Creates the Staging.Fact_FixtureFinance table
Changes
Developer		Date		Change
----------------------------------------------------------------------------------------------------------
Brian Boswick	04/13/2019	Added LoadPortBerthKey and DischargePortBerthKey
Brian Boswick	01/31/2020	Added LoadPortKey and DischargePortKey
Brian Boswick	02/06/2020	Added ChartererKey and OwnerKey
Brian Boswick	07/29/2020	Added COAKey
==========================================================================================================	
*/

drop table if exists Staging.Fact_FixtureFinance;
go

create table Staging.Fact_FixtureFinance
	(
		PostFixtureAlternateKey			int					not null,
		RebillAlternateKey				int					not null,
		ChargeAlternateKey				int					not null,
		ParcelProductAlternateKey		int					not null,
		ProductAlternateKey				int					not null,
		ParcelAlternateKey				int					not null,
		ChargeTypeAlternateKey			smallint			not null,
		LoadPortBerthKey				int					not null,
		DischargePortBerthKey			int					not null,
		LoadPortKey						int					not null,
		DischargePortKey				int					not null,
		ProductKey						int					not null,
		ParcelKey						int					not null,
		PostFixtureKey					int					not null,
		VesselKey						int					not null,
		CharterPartyDateKey				int					not null,
		FirstLoadEventDateKey			int					not null,
		ChartererKey					int					not null,
		OwnerKey						int					not null,
		COAKey							int					not null,
		ChargeType						nvarchar(500)		null,		-- Degenerate Dimension Attributes
		ChargeDescription				nvarchar(500)		null,
		ParcelNumber					smallint			null,
		Charge							decimal(20, 8)		null,		-- Metrics
		ChargePerMetricTon				decimal(20, 8)		null,
		AddressCommissionRate			decimal(20, 8)		null,
		AddressCommissionAmount			decimal(20, 8)		null,
		AddressCommissionApplied		decimal(20, 8)		null
	) on [primary];