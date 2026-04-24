/*
===========================
Create Database and Schemas
===========================
Script Purpose:
This script creates a new database named 'DataWarehouse' after checking if it already exists. 
If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
within the database: 'bronze', 'silver', and 'gold'.

WARNING: 
Running this script will drop the entire 'DataWarehouse' database if it exists. 
All data in the database will be permanently deleted. Proceed with caution 
and ensure you have proper backups before running this script.
*/

use master;
Go
  
-- Drop and recreate the 'DataWarehouse' database 
If Exists (select 1 from sys.databases where name = 'DataWarehosue')
	Begin
		Alter Database DataWarehouse Set Single_user with Rollback Immediate;
		Drop Database DataWarehouse;
	END;
  Go

--Create the 'DataWarehouse' database
Create database DataWarehouse;
Go
  
Use Database Datawarehouse;
Go

--Create Schemas
Create Schema bronze;
Go

Create schema silver;
Go

Create schema gold;
Go

