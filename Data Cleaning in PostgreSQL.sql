SELECT *
FROM public."Housing Project";


--To check rows with null Property Address values
SELECT *
FROM public."Housing Project"
WHERE "PropertyAddress" IS NULL
ORDER BY "ParcelID";



--Populate the Property Address Data by Self Join
	
SELECT HP1."ParcelID", 
	HP1."PropertyAddress",
	HP2."ParcelID",
	HP2."PropertyAddress",
	COALESCE(HP1."PropertyAddress", HP2."PropertyAddress")
FROM public."Housing Project" AS HP1
JOIN public."Housing Project" AS HP2
	ON HP1."ParcelID" = HP2."ParcelID"
	AND HP1."UniqueID" <> HP2."UniqueID"
WHERE HP1."PropertyAddress" IS NULL;


UPDATE public."Housing Project" AS HP1
SET "PropertyAddress" = COALESCE(HP1."PropertyAddress", HP2."PropertyAddress")
FROM public."Housing Project" AS HP2
WHERE HP1."ParcelID" = HP2."ParcelID"
  AND HP1."UniqueID" <> HP2."UniqueID"
  AND HP1."PropertyAddress" IS NULL;
--There are no null values after Updating the table


--Breaking out Address into Individual Columns(Address, City, State)
SELECT "PropertyAddress"
FROM public."Housing Project";


SELECT 
    SUBSTRING("PropertyAddress" FROM 1 FOR POSITION(',' IN "PropertyAddress") - 1) AS Address,
	SUBSTRING("PropertyAddress" FROM POSITION(',' IN "PropertyAddress") + 1) AS Address2
FROM public."Housing Project";


-- Add the new columns
ALTER TABLE public."Housing Project"
ADD "PropertyNewAddress" text,
ADD "PropertyCity" text;

-- Update the new columns with the split values
UPDATE public."Housing Project"
SET "PropertyNewAddress" = SUBSTRING("PropertyAddress" FROM 1 FOR POSITION(',' IN "PropertyAddress") - 1),
    "PropertyCity" = SUBSTRING("PropertyAddress" FROM POSITION(',' IN "PropertyAddress") + 1);


SELECT  "PropertyNewAddress",
	"PropertyCity" 
FROM public."Housing Project";


--Splitting Owner Address into Address, City and State
SELECT
	SPLIT_PART("OwnerAddress", ',', 1) AS OwnerStreet,
	SPLIT_PART("OwnerAddress", ',', 2) AS OwnerCity,
	SPLIT_PART("OwnerAddress", ',', 3) AS OwnerState
FROM public."Housing Project";

ALTER TABLE public."Housing Project"
ADD "OwnerStreet" text,
ADD "OwnerCity" text,
ADD "OwnerState" text;

UPDATE public."Housing Project"
SET "OwnerStreet" = SPLIT_PART("OwnerAddress", ',', 1),
	 "OwnerCity" = SPLIT_PART("OwnerAddress", ',', 2),
	 "OwnerState" = SPLIT_PART("OwnerAddress", ',', 3);

SELECT "OwnerStreet", "OwnerCity", "OwnerState"
FROM public."Housing Project";


--Change the Y and N in the Sold As Vacant Column
SELECT 
	CASE
		WHEN "SoldasVacant" = 'N' THEN 'No'
		WHEN "SoldasVacant" = 'Y' THEN 'Yes'
		ELSE "SoldasVacant"
		END
FROM public."Housing Project";

UPDATE  public."Housing Project"
SET "SoldasVacant" = CASE
		WHEN "SoldasVacant" = 'N' THEN 'No'
		WHEN "SoldasVacant" = 'Y' THEN 'Yes'
		ELSE "SoldasVacant"
		END;

SELECT DISTINCT("SoldasVacant"), COUNT("SoldasVacant")
FROM public."Housing Project"
GROUP BY "SoldasVacant";



--Delete Duplicate Values
WITH Row_Num_CTE AS (
    SELECT 
        "UniqueID",
        ROW_NUMBER() OVER (
            PARTITION BY 
                "ParcelID",
                "PropertyAddress",
                "SalePrice",
                "SaleDate",
                "LegalReference"
            ORDER BY "UniqueID"
        ) AS Row_num
    FROM public."Housing Project"
)
DELETE FROM public."Housing Project"
WHERE "UniqueID" IN (
    SELECT "UniqueID"
    FROM Row_Num_CTE
    WHERE Row_num > 1
);


--Delete Unused Columns
SELECT * 
FROM public."Housing Project"


ALTER TABLE public."Housing Project"
DROP COLUMN "OwnerAddress",
DROP COLUMN "PropertyAddress";
