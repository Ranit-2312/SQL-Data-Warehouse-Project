/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.*/

DROP DATABASE IF EXISTS "DataWarehouse" WITH (FORCE);

-- creating the database
CREATE DATABASE DataWarehouse;

-- creating the bronze schema
CREATE SCHEMA bronze;

-- creating the silver schema
CREATE SCHEMA silver;

-- creating the gold schema
CREATE SCHEMA gold;


