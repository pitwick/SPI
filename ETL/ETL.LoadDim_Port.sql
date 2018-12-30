/*
==========================================================================================================
Author:			Brian Boswick
Create date:	12/30/2018
Description:	Creates the LoadDim_Port stored procedure
Changes
Developer		Date		Change
----------------------------------------------------------------------------------------------------------
==========================================================================================================	
*/

set ansi_nulls on;
go
set quoted_identifier on;
go

drop procedure if exists ETL.LoadDim_Port;
go

create procedure ETL.LoadDim_Port
as
begin

	declare	@NewRecord		smallint = 1,
			@ExistingRecord smallint = 2,
			@Type1Change	smallint = 4,
			@ErrorMsg		varchar(1000);

	-- Clear Staging table
	if object_id(N'Staging.Dim_Port', 'U') is not null
		truncate table Staging.Dim_Port;

	begin try
		insert
				Staging.Dim_Port
		select
				[port].QBRecId,
				[port].PortName,
				[port].City,
				[port].StateRegion,
				[port].Country,
				[port].Comments,
				[port].Latitude,
				[port].Longitude,
				[port].PortCosts,
				0 Type1HashValue,
				isnull(rs.RecordStatus, @NewRecord) RecordStatus
			from
				[Ports] [port]
					left join	(
									select
											@ExistingRecord RecordStatus,
											PortAlternateKey
										from
											Warehouse.Dim_Port
								) rs
						on rs.PortAlternateKey = [port].QBRecId;
	end try
	begin catch
		select @ErrorMsg = 'Staging Port records - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch	

	-- Generate hash values for Type 1 changes. Only Type 1 SCDs
	begin try
		update
				Staging.Dim_Port
			set
				-- Type 1 SCD
				Type1HashValue =	hashbytes	(
													'MD2',
													concat	(
																PortName,
																City,
																StateRegion,
																Country,
																Comments,
																Latitude,
																Longitude,
																PortCosts
															)
												);
		
		update
				Staging.Dim_Port
			set
				RecordStatus += @Type1Change
			from
				Warehouse.Dim_Port wp
			where
				wp.PortAlternateKey = Staging.Dim_Port.PortAlternateKey
				and wp.Type1HashValue <> Staging.Dim_Port.Type1HashValue;
	end try
	begin catch
		select @ErrorMsg = 'Updating hash values - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch

	-- Insert new ports into Warehouse table
	begin try
		insert
				Warehouse.Dim_Port
			select
					[port].PortAlternateKey,
					[port].PortName,
					[port].City,
					[port].StateRegion,
					[port].Country,
					[port].Comments,
					[port].Latitude,
					[port].Longitude,
					[port].PortCosts,
					[port].Type1HashValue,
					getdate() RowStartDate,
					getdate() RowUpdatedDate,
					'Y' IsCurrentRow
				from
					Staging.Dim_Port [port]
				where
					[port].RecordStatus & @NewRecord = @NewRecord;
	end try
	begin catch
		select @ErrorMsg = 'Loading Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch

	-- Update existing records that have changed
	begin try
		update
				Warehouse.Dim_Port
			set
				PortName = [port].PortName,
				City = [port].City,
				StateRegion = [port].StateRegion,
				Country = [port].Country,
				Comments = [port].Comments,
				Latitude = [port].Latitude,
				Longitude = [port].Longitude,
				PortCosts = [port].PortCosts,
				Type1HashValue = [port].Type1HashValue,
				RowUpdatedDate = getdate()
			from
				Staging.Dim_Port [port]
			where
				[port].RecordStatus & @ExistingRecord = @ExistingRecord
				and [port].PortAlternateKey = Warehouse.Dim_Port.PortAlternateKey
				and RecordStatus & @Type1Change = @Type1Change;
	end try
	begin catch
		select @ErrorMsg = 'Updating existing records in Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch

	-- Insert Unknown record
	begin try
		if not exists (select 1 from Warehouse.Dim_Port where PortKey = -1)
		begin
			set identity_insert Warehouse.Dim_Port on;
			insert
					Warehouse.Dim_Port	(
														PortKey,
														PortAlternateKey,
														PortName,
														City,
														StateRegion,
														Country,
														Comments,
														Latitude,
														Longitude,
														PortCosts,
														Type1HashValue,
														RowCreatedDate,
														RowUpdatedDate,
														IsCurrentRow
													)

				values	(
							-1,				-- PortKey
							0,				-- PortAlternateKey
							'Unknown',		-- PortName
							'Unknown',		-- City
							'Unknown',		-- StateRegion
							'Unknown',		-- Country
							'Unknown',		-- Comments
							'Unknown',		-- Latitude
							'Unknown',		-- Longitude
							'Unknown',		-- PortCosts
							0,				-- Type1HashValue
							getdate(),		-- RowCreatedDate
							getdate(),		-- RowUpdatedDate
							'Y'				-- IsCurrentRow
						);
			set identity_insert Warehouse.Dim_Port off;
		end
	end try
	begin catch
		select @ErrorMsg = 'Inserting Unknown record into Warehouse - ' + error_message();
		throw 51000, @ErrorMsg, 1;
	end catch
end