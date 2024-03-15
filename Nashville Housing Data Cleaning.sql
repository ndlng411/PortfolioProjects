--Standardize Date Format--
select SaleDate1
from NashvilleHousing

update NashvilleHousing
set SaleDate1 = CONVERT(date,SaleDate)
--> This should have worked on its own to update the original 'SaleDate' Column
---> If it doesn' work, use the 'Alter' function where we will 'Add' a new column with the desired formate
----> Then we run the 'Update' function except we will now update the newly created column to have the desired format from the original column
alter table nashvillehousing
add SaleDate1 date

--Populate property address data--
select *
from NashvilleHousing
where PropertyAddress is null
--> So here, some of the property adresses are 'NULL' and we need to find a way to have the right addresses there
---> The method we will be using here is that we will look for parcel IDs that are similar where one has the address and the other doesn't and we will fill them
----> To do that, we will have to join the table to itself using the 'ParcelID' but to have the parcelID joind with the same parcelID number but from a different row so that we could find if the address was written correctly for it in another row, we need to specify that the Join will link different 'UniqeIds'
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
--> Now we have the same PacelID joined by itself but from a different row because of the unique id condition
---> the ISNULL part is to show what we will put instead of the NULL
--> Now we need to UPDATE the Null part with the replacement in the ISNULL
Update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
--> Now return and run the previous function and it will return nothing
--> We should know that when update a JOIN function, we have to use the alias i.e. "a" 


--Breaking Out Address into Individual Columns (Address, City, State)
select PropertyAddress
from PortfolioProject..NashvilleHousing
--First: Take the adrress by stopping at the comma that exists before the city
select
SUBSTRING(PropertyAddress, 1, charindex(',', PropertyAddress)-1) Address
from PortfolioProject..NashvilleHousing
--> So, it's the SUBSTRING that takes a part of the string, Inside we define the column we want to take a part from 'PropertyAddress', Then where to start from '1', Then the CHARINDEX where we don't want to stop at a specific order but at a symbole ',' in PropertyAddress. The final '-1' is for going back one step in order not to take the comma with us
--> For the city we will easily reverse things, start from the CHARINDEX and +1 so that we start after the comma, then we go until the full length (LEN) left of the PropertyAddress
select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
from PortfolioProject..NashvilleHousing
--> Now we create the 2 columns to add them
Alter table PortfolioProject..NashvilleHousing
Add Address nvarchar(255)

update PortfolioProject..NashvilleHousing
set Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

Alter table PortfolioProject..NashvilleHousing
Add City nvarchar(255)

update PortfolioProject..NashvilleHousing
set City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
--> Run the 'ALTER' function to add the column first
--> Then run the update function to add data to that new column
---> Now Check..
select *
from PortfolioProject..NashvilleHousing
--> The 2 columns are added to the end
---> We need to separate the Owner address too, but it has two commas so, we won't be able to use the SUBSTRING function
---> We can use the PARSENAME which is less complicated than the SUBSTRING but only separates at 'Dots' not commas so, inside the parsename we will replace the commas with dots
select OwnerAddress
from PortfolioProject..NashvilleHousing --just to see how it looks--

select
PARSENAME(Replace(OwnerAddress, ',', '.'), 3)
from PortfolioProject..NashvilleHousing
--The other thing with the PARSENAME is that it separates backwards, so we picked '3' rd part as we knew it will separate the owneraddress into 3 parts and '3' will give us the first one
select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
from PortfolioProject..NashvilleHousing
--> Now add them for real
Alter Table PortfolioProject..NashvilleHousing
Add OwnerAddress1 nvarchar(255)

Update PortfolioProject..NashvilleHousing
set OwnerAddress1 = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

Alter Table PortfolioProject..NashvilleHousing
Add OwnerCity1 nvarchar(255)

Update PortfolioProject..NashvilleHousing
set OwnerCity1 = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

Alter Table PortfolioProject..NashvilleHousing
Add OwnerState1 nvarchar(255)

Update PortfolioProject..NashvilleHousing
set OwnerState1 = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--> Now check them at the end
select *
from PortfolioProject..NashvilleHousing
--> N.B: Again, Run the 'ALTER' first then run the 'UPDATE' one at a time

--Change 'Y' &  'N' into 'Yes' and 'No
-->The column 'SoldAsVacant' has yes, No, Y and N and we want to nmake them all yes and no
--> I am sure there are many ways to do that but here we will use a CASE statement

select SoldAsVacant, count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant			--Just to see them--

select SoldAsVacant,
case when SoldAsVacant = 'Y' Then 'Yes'
	 when SoldAsVacant = 'N' Then 'No'
	 Else SoldAsVacant
End
from PortfolioProject..NashvilleHousing

update PortfolioProject..NashvilleHousing
set SoldAsVacant = case 
	 when SoldAsVacant = 'Y' Then 'Yes'
	 when SoldAsVacant = 'N' Then 'No'
	 Else SoldAsVacant
End
--> Now Check
Select SoldAsVacant, count(soldasvacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
------Voila-----

--------------------------------REMOVE DUPLICATES--------------------------------------
SELECT *
from PortfolioProject..NashvilleHousing
--> Here we will use 'ROW_NUMBER' function which when detects two identical values in the same partition, it assigns different rank numbers to both. Of course for that it will be followed by 'OVER() PARTITION BY' as we will need to specify what columns we will need to state that the rows are duplicates based on
select *,
		ROW_NUMBER() over(
		partition by ParcelID,
					 PropertyAddress,
					 SalePrice,
					 LegalReference
		order by UniqueID
		) row_num
from PortfolioProject..NashvilleHousing
--> The 'row_num' here is not an actual column in the table and we don't need to alter and add the column to the table to filter and delete values based on it.
--> so we will use CTE [Temp Table] like thing
WITH RowNumCTE as(
select *,
		ROW_NUMBER() over (
		partition by ParcelID,
					 PropertyAddress,
					 SalePrice,
					 LegalReference
					 order by uniqueID
					 ) row_num
from PortfolioProject..NashvilleHousing
)
--> Now we can use the temporarily added column to see the duplicates
select *
from RowNumCTE
where row_num > 1
--> N.B: We should run the whole CTE with the query to get the result
-->Now we remove the duplicates
delete
from RowNumCTE
where row_num > 1
--> Now check the previously commented query again to see if there are any duplicates
--> Removing Duplicates is not very recommended in SQL

------------------------------DELETE UNUSED COLUMNS------------------------------------
Select *
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

------------------------That's it for the Cleaning Data Project------------------------
--04:28:41--