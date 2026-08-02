/*
============================================================================
Create Database and Schema
============================================================================
Script Purpose:
  This script create a new database named 'DataWarehouse' after checking if it alreadty exists.
  If the database exists, it is dropped and recreated. Additionaly, the script set up threee schemas
  within the database: 'bronze', 'silver', and 'gold'.
Warning:
  Ruining this script will drop the entire 'DatawWrehouse' database if it exists.
  All data in the database will be permanently deleted. Proceed with cuation
  and ensure you have proper backups before runing the script.
*/

*****************************************************************************
  
use master;
go

-- Drop and recreate the 'DataWarehouse' database
if exists(select 1 from sys.databases where name='DataWarehouse')
begin
	Alter database Datawarehouse set Single_User with Rollback immediate;
	Drop Database DataWarehouse;
End;
go


-- Create 'DatabaseWarehouse' database
create database DataWarehouse;
go
use DataWarehouse;
go
Create schema bronze;
go
Create schema silver;
go
Create schema gold;
go
