/* 
Cleaning Data in SQL Queries
*/

Select *
From PortfolioProject..Nashville

-- REFORMATE SALEDATE

-- use cast(arg as new type) or CONVERT(new type, arg)
Select SaleDatev2, cast(SaleDate as date)
From PortfolioProject..Nashville

Alter Table Nashville
Add SaleDatev2 Date;

Update Nashville
Set SaleDatev2 = CONVERT(Date, SaleDate)

-- POPULATE PROPERTYADDRESS

/*
Certain rows had a null PropertyAddress, yet they shared the same ParcelID with other rows.
To fix this, join the table on itself.
Use ISNULL() to populate all the 'null' values with the correct address
*/
Select v1.ParcelID, v1.PropertyAddress, v2.ParcelID, v2.PropertyAddress, ISNULL(v1.PropertyAddress, v2.PropertyAddress)
From Nashville v1
Join Nashville v2
	On v1.ParcelID = v2.ParcelID
	And v1.[UniqueID ] != v2.[UniqueID ]
Where v1.PropertyAddress is null

-- When updating using JOIN, you must use the alias not the table name
Update v1
Set PropertyAddress = ISNULL(v1.PropertyAddress, v2.PropertyAddress)
From Nashville v1
Join Nashville v2
	On v1.ParcelID = v2.ParcelID
	And v1.[UniqueID ] != v2.[UniqueID ]
Where v1.PropertyAddress is null

-- SPLIT UP PROPERTYADDRESS (Address, City)

Select PropertyAddress, OwnerAddress
From Nashville

-- CHARINDEX() to find the comma that separates the address from the city/state
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
From Nashville

-- Create 2 new columns to hold the new separated values
Alter Table Nashville
Add 
AddressProperty nvarchar(255),
CityProperty nvarchar(255);

Update Nashville
Set 
AddressProperty = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
CityProperty = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- SPLIT UP OWNERADDRESS (Address, City, State) 
-- PARSENAME() only works using periods, can split up delimited data
Select 
PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
From Nashville

Alter Table Nashville
ADD 
AddressOwner nvarchar(255),
CityOwner nvarchar(255), 
StateOwner nvarchar(255);

Update Nashville
Set 
AddressOwner = PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
CityOwner = PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
StateOwner = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

-- CHANGE Y -> YES AND N -> NO in 'SoldAsVacant' COLUMN

-- check if update works
Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From Nashville
Group by SoldAsVacant
Order by 2

Select SoldAsVacant,
Case
	When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
END
From Nashville

Update Nashville
Set SoldAsVacant = 
	Case 
		When SoldAsVacant = 'Y' Then 'Yes'
		When SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
	END

-- REMOVE DUPLICATES 
WITH Duplicate as 
(
Select *,
	ROW_NUMBER() OVER (
	Partition by 
	ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference,
	OwnerAddress
	Order by
		UniqueID) dup
From Nashville
)

DELETE
From Duplicate
Where dup > 1

-- Delete unused columns (nulls)

Select * 
From Nashville

Alter Table Nashville
DROP COLUMN 
	OwnerAddress,
	PropertyAddress,
	SaleDate,
	TaxDistrict