/*
===================================================================================
Stored Procedure: Load Silver Layer (Bronze-> Silver)
===================================================================================
Script Purpose:
  This stored procedure perform the ETL (Etract,Tranfor,Load) process to populate
  the silver schema table from the bronze schema. 
action performed:
  - Truncate Silver Tables
  - Inserts transformed and cleaned data from bronzeinto Silver Tables.

Parameters:
  None.
  This stored procedure does not accept any parameteers or return any values. 

Usage Example:
  EXEC Silver.load_silver;
===================================================================================
*/

create or alter procedure silver.load_silver as
begin
begin try
		print'====================================================================';
		print 'Loading Silver Layer';
		print'====================================================================';

		print '-------------------------------------------------------------------';
		print 'Loading CRM Tables';
		print '-------------------------------------------------------------------';
	print '>> Truncating Table:silver.crm_cust_info'; 
	truncate table silver.crm_cust_info;
	print '>> Inserting Data Into:silver.crm_cust_info'; 
	insert into silver.crm_cust_info(
		cust_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gendr,
		cst_date
	)
	select 
	cust_id,
	cst_key,
	trim(cst_firstname) as cst_firstname,
	trim(cst_lastname) as cst_lastname,
	case  upper(trim(cst_material_status ))
			when 'M' then 'Marreid'
			when 'S' then 'Single'
	else 'n/a'
	end as cst_maritial_status,
	case  upper(trim(cst_gendr ))
			when 'M' then 'Maale'
			when 'F' then 'Female'
	else 'n/a'
	end as cst_gendr,
	cst_date

	from (
			select *,
			row_number () over (partition by cust_id order by cst_date desc) as flag
			from bronze.crm_cust_info
				where cust_id is not null
			)t where flag =1;


	print '>> Truncating Table:silver.crm_prd_info'; 
	truncate table silver.crm_prd_info;
	print '>> Inserting Data Into:silver.crm_prd_info'; 
	insert into silver.crm_prd_info(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	select 
	prd_id,
	replace(substring(prd_key,1,5), '-', '_') as cat_id,
	SUBSTRING(prd_key,7,len(prd_key)) as prd_key,
	prd_nm,
	isnull(prd_cost,0) as prd_cost,
	case upper(trim(prd_line))
			when 'M' then 'Moutain'
			when 'S' then 'Orther Sales'
			when 'R' then 'Road'
			when 'T' then 'Touring'
		else 'n/a'
	end as prd_line,
	cast (prd_start_dt as date) as pr_start_dt,
	cast( lead(prd_start_dt)over (partition by prd_key order by prd_start_dt)-1 as date)  as prd_end_dt
	from bronze.crm_prd_info;


	print '>> Truncating Table:silver.crm_sales_details'; 
	truncate table silver.crm_sales_details;
	print '>> Inserting Data Into:silver.crm_sales_details'; 
	insert into silver.crm_sales_details(
		sls_ord_nm ,
		sls_prd_key ,
		sls_cust_id ,
		sls_order_dt ,
		sls_ship_dt ,
		sls_due_dt ,
		sls_sales ,
		sls_quantity,
		sls_price
	)
	select
	sls_ord_nm,
	sls_prd_key,
	sls_cust_id,
	case when sls_order_dt = 0 or len(sls_order_dt ) != 8 then Null
	else CAST( cast ( sls_order_dt as varchar) as date)
	end sls_order_date,
	case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then Null
	else CAST( cast ( sls_ship_dt as varchar) as date)
	end sls_ship_dt,
	case when sls_due_dt = 0 or len(sls_due_dt) != 8 then Null
	else CAST( cast ( sls_due_dt as varchar) as date)
	end sls_due_dt,
	case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs (sls_price)
			then sls_quantity * abs(sls_price)
		else sls_sales
	end as sls_sales,
	sls_quantity,
	case when sls_price is null or sls_price <=0
			then sls_sales / nullif (sls_quantity,0)
	else sls_price
	end as sls_price 
	from bronze.crm_sales_details;

	print '-------------------------------------------------------------------';
	print 'Loading ERP Tables';
	print '-------------------------------------------------------------------';

	print '>> Truncating Table: silver.erp_cust_az12';
	truncate table silver.erp_cust_az12;
	print '>> Inserting Data Into:silver.erp_cust_az12'; 
	insert into silver.erp_cust_az12 (
		cid,
		bdate,
		gen
	)
	select 
	case when CID like'NAS%' then substring(CID,4, len (CID))
	else CID
	end CID,
	case when BDATE > GETDATE() then null
		else BDATE
	End as BDATE,
	case when upper (trim(GEN)) in ('F', 'Female') then 'Female'
		when upper (trim(GEN)) in ('M', 'Male') then 'Male'
		else 'n/a'
	end as GEN
	from bronze.erp_cust_az12;

	print '>> Truncating Table:silver.erp_loc_a101';
	truncate table silver.erp_loc_a101;
	print '>> Inserting Data Into: silver.erp_loc_a101';
	insert into silver.erp_loc_a101(
		cid,
		cntry
	)
	select
	replace (CID,'-','') as CID,
	case when TRIM(CNTRY) = 'DE' then 'Germany'
		when TRIM(CNTRY)	IN ('us','usa') THEN 'United States'
		when TRIM(CNTRY) = '' or CNTRY IS NULL THEN 'N/A'
		ELSE TRIM(CNTRY)
	end as CNTRY
	from bronze.erp_loc_a101;

	print '>> Truncating Table: silver.erp_px_cat_g1v2';
	truncate table silver.erp_px_cat_g1v2;
	print '>> Inserting Data Into: silver.erp_px_cat_g1v2';
	insert into silver.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintainance
	)
	select
	ID,
	CAT,
	SUBCAT,
	MAINTENANCE
	from bronze.erp_px_cat_g1v2;
	end try
	begin catch
		print '================================================================='
		print 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		print 'ERROR MESSAGE' + ERROR_MESSAGE();
		print 'ERROR MESSAGE' + CAST (ERROR_NUMBER () AS NVARCHAR) ;
		print 'ERROR MESSAGE' + CAST (ERROR_STATE () AS NVARCHAR) ;
		print '================================================================='
	end catch
end
