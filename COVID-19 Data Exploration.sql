--Select tha data to analyse
SELECT location, date::date, population, total_cases, new_cases, total_deaths
FROM public."CovidDeaths";


--Changing the data type of the Date column from Text to Date type for accurate analysis
ALTER TABLE public."CovidDeaths"
ALTER COLUMN date TYPE date USING TO_DATE(date::text, 'DD-MM-YYYY');

ALTER TABLE public."CovidVaccinations"
ALTER COLUMN date TYPE date USING TO_DATE(date::text, 'DD-MM-YYYY');


--Looking at Total cases vs Total deaths
--Shows the possibility of dying if infected with Covid-19
SELECT 
	location, 
	date,
	total_cases,
	total_deaths, (total_deaths::numeric/total_cases)*100 AS Death_percentage
FROM public."CovidDeaths"
WHERE  location LIKE '%Nigeria%'
ORDER BY date ASC;



--Looking at the Total No. of cases vs Total Population
--Show the percentage of people who got infected with Covid-19 
SELECT 
	location,
	date,
	population,
	total_cases,
	(total_cases::numeric/population::bigint)* 100 AS infected_percentage
FROM public."CovidDeaths"
WHERE  location LIKE '%Nigeria%'
ORDER BY location ASC;


--The countries with the highest infection rate when compared to their population
SELECT 
	location, 
	Population, 
	MAX(total_cases) AS Highest_infection_count, 
	MAX((total_cases::numeric/population::bigint))* 100 AS infected_popul_percentage
FROM public."CovidDeaths"
WHERE "total_cases" IS NOT NULL
GROUP BY location, population
ORDER BY infected_popul_percentage DESC;


--The Top 20 Countries with Highest Death Count
SELECT 
	location,  
	MAX(total_deaths) AS Highest_death_count
FROM public."CovidDeaths"
WHERE "total_deaths" IS NOT NULL 
	AND "continent" IS NOT NULL
GROUP BY location
ORDER BY Highest_death_count DESC
LIMIT 20;


--Showing the Continents with the Highest Death Counts per Population
SELECT continent, 
		MAX(Total_deaths::integer) AS total_death_count
FROM public."CovidDeaths"
WHERE "continent" IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


--Global Numbers 
SELECT 
    SUM(new_cases::int) AS total_cases,
    SUM(new_deaths::int) AS total_deaths,
    SUM(new_deaths::int)::numeric / NULLIF(SUM(new_cases::int), 0) * 100 AS death_percentage
FROM public."CovidDeaths"
WHERE continent IS NOT NULL


--Global numbers by date
SELECT 
	date,
    SUM(new_cases::int) AS total_cases,
    SUM(new_deaths::int) AS total_deaths,
    SUM(new_deaths::int)::numeric / NULLIF(SUM(new_cases::int), 0) * 100 AS death_percentage
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


--Covid Deaths and Vaccinations
--Total Population vs Vaccinations
SELECT deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population,
	vaccine.new_vaccinations,
	SUM(vaccine.new_vaccinations::int)
			OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS  Rolling_people_Vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3;


WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
	SELECT deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population,
	vaccine.new_vaccinations,
	SUM(vaccine.new_vaccinations::int)
			OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS  Rolling_people_Vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3;
)

SELECT *, (Rolling_People_Vaccinated::numeric/Population::int)*100 AS vaccinated_percentage
FROM PopvsVac


--Temp Table
DROP TABLE IF EXISTS Percentage_Popul_Vaccinated
CREATE TABLE Percentage_Popul_Vaccinated
(
Continent text,
Location text,
Date date,
Population numeric,
New_vaccinations numeric,
Rolling_People_Vaccinated numeric
);

INSERT INTO Percentage_Popul_Vaccinated
SELECT deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population::numeric,
	vaccine.new_vaccinations::numeric,
	SUM(vaccine.new_vaccinations::numeric)
			OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS  Rolling_people_Vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date;
--WHERE deaths.continent IS NOT NULL;

SELECT *, (Rolling_People_Vaccinated::numeric/Population::numeric)*100 AS vaccinated_percentage
FROM  Percentage_Popul_Vaccinated


--Creating view to store data for later
CREATE VIEW Percent_Population_Vaccinated AS
SELECT deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population,
	vaccine.new_vaccinations,
	SUM(vaccine.new_vaccinations::int)
			OVER(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS  Rolling_people_Vaccinated
FROM public."CovidDeaths" AS deaths
JOIN public."CovidVaccinations" AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL;
