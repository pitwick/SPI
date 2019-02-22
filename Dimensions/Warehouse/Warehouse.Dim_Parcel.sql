/*
==========================================================================================================
Author:			Brian Boswick
Create date:	02/21/2019
Description:	Creates the Warehouse.Dim_Parcel table
Changes
Developer		Date		Change
----------------------------------------------------------------------------------------------------------
==========================================================================================================	
*/

drop table if exists Warehouse.Dim_Parcel;
go

create table Warehouse.Dim_Parcel
	(
		ParcelKey				int					not null identity(1, 1),
		ParcelAlternateKey		int					not null,
		BillLadingDate			date				null,
		ParcelFrtRate			decimal(18, 2)		null,
		OutTurnQty				decimal(18, 2)		null,
		ShipLoadedQty			decimal(18, 2)		null,
		ShipDischargeQty		decimal(18, 2)		null,
		NominatedQty			decimal(18, 2)		null,
		BLQty					decimal(18, 2)		null,
		Comments				nvarchar(2500)		null,
		LumpsumPayment			nvarchar(100)		null,
		Unit					nvarchar(20)		null,
		Type1HashValue			varbinary(16)		not null,
		RowCreatedDate			datetime			not null,
		RowUpdatedDate			datetime			not null,
		IsCurrentRow			char(1)				not null,
		constraint [PK_Warehouse_Dim_Parcel_Key] primary key clustered 
		(
			ParcelKey asc
		)
			with 
				(pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on) 
			on [primary]
	) on [primary];