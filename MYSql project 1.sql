select * from hdata;

-- 1) change data type text to date

select * from hdata;
alter table hdata add Sdate date;
UPDATE hdata
SET Sdate = STR_TO_DATE(saleDate, '%M %d, %Y');
ALTER TABLE hdata DROP COLUMN SaleDate;
ALTER TABLE hdata RENAME COLUMN Sdate TO SaleDate;
alter table hdata drop column Sdate;
select * from hdata;

-- 2) populate property address data
select PropertyAddress from hdata;

select PropertyAddress from hdata
where PropertyAddress is null;

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull(a.PropertyAddress,b.PropertyAddress)
from hdata a
join hdata b
on a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;

 
 UPDATE hdata a
JOIN hdata b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- 3) breaking down address into individual column (address, city, state)

select PropertyAddress from hdata;
select 
substring_index(PropertyAddress,',',1) as street,
substring_index(PropertyAddress,',',-1) as city
from hdata;

alter table hdata
add PA_street varchar(50),
add PA_city varchar(50);

update hdata
set PA_street = substring_index(PropertyAddress,',',1),
    PA_city = substring_index(PropertyAddress,',',-1);

select OwnerAddress from hdata;
select 
substring_index(OwnerAddress,',',1) as street,
substring_index(substring_index(OwnerAddress,',', -2), ',',1) as city,
substring_index(OwnerAddress,',',-1) as state
from hdata;

alter table hdata
add OA_street varchar(50),
add	OA_city varchar(50),
add   OA_state varchar(50);

update  hdata
set OA_street= substring_index(OwnerAddress,',',1),
 OA_city= substring_index(substring_index(OwnerAddress,',', -2), ',',1),
 OA_state= substring_index(OwnerAddress,',',-1);
 
  -- 4) change Y and N to Yes And No in SoldAsVacant field
 
 select distinct(SoldAsVacant), count(SoldAsVacant) 
 from  hdata
 group by SoldAsVacant
 order by count(SoldAsVacant);
 
 update hdata
 set SoldAsVacant= case when SoldAsVacant= 'N' then 'No'
      when SoldAsVacant= 'Y' then 'Yes'
       else SoldAsVacant
   end;
   
   -- 5) remove duplicate
   
   SELECT *,
    CASE
        WHEN ROW_NUMBER() OVER 
        (PARTITION BY ParcelID,
					  PropertyAddress,
	                  SalePrice,
					  LegalReference,
					  SaleDate ORDER BY UniqueID) = 1 THEN 1
        ELSE 2
    END AS RowType
FROM
    hdata;
    
    ALTER TABLE hdata
ADD COLUMN RowType INT;

-- update data to new column 

UPDATE hdata AS t1
JOIN (
    SELECT
        UniqueID,
        CASE
            WHEN ROW_NUMBER() OVER 
            (PARTITION BY ParcelID,
					  PropertyAddress,
	                  SalePrice,
					  LegalReference,
					  SaleDate ORDER BY UniqueID) = 1 THEN 1
            ELSE 2
        END AS RowType
    FROM hdata
) AS t2
ON t1.UniqueID = t2.UniqueID
SET t1.RowType = t2.RowType;

-- count how many row have duplicate 
select count(RowType), RowType from hdata
where RowType > 1
group by RowType;

-- delete duplicate row
DELETE FROM hdata
WHERE RowType > 1;


-- 6) delete unused column 
select * from hdata;

alter table hdata
drop column PropertyAddress, 
drop column OwnerAddress,
drop column TaxDistrict;

 








