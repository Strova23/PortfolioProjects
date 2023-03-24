-- Select Data
Select location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..['CovidDeaths$']
--Must include this to get rid of the locations that are labeled as whole continents along with the 'type of income' categories
WHERE continent is NULL and location NOT LIKE '%income%'
Order by 1, 2

-- Need to alter datatypes (datatype: nvarchar can't be used when dividing)
ALTER TABLE PortfolioProject..['CovidDeaths$']
ALTER COLUMN total_cases decimal

ALTER TABLE PortfolioProject..['CovidDeaths$']
ALTER COLUMN total_deaths decimal

ALTER TABLE PortfolioProject..['CovidDeaths$']
ALTER COLUMN population decimal

-- Total Cases v Total Deaths
-- Estimated chance to die from Covid in your country (filter by location)
Select continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathperc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Order by 1, 2

-- Chance to die from COVID based on Continent
Select continent, AVG((total_deaths/total_cases)*100) as deathperc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
GROUP BY continent

-- Total Cases v Population
-- Countries with most infected by COVID
Select location, date, total_cases, population, (total_cases/population)*100 as hasCovid
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Order by 1, 2

-- Continents with most infected by COVID
Select continent, MAX((total_cases/population)*100) as hasCovid
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
GROUP BY continent

-- Countries with highest infection rate
Select location, population, MAX(total_cases) as mostInfections, MAX((total_cases/population))*100 as hasCovid
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Group by location, population
Order by hasCovid desc

-- Continents with highest infection rate
Select continent, cast(AVG(population) as int) as AVG_Population, MAX((total_cases/population))*100 as infection_perc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Group by continent
Order by infection_perc desc

-- Countries with highest death rate
Select location, population, MAX(total_deaths) as mostDeaths, MAX((total_deaths/population))*100 as deathPerc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Group by location, population
Order by deathPerc desc

-- Countries with highest death count
Select continent, MAX(total_deaths) as mostDeaths
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Group by continent
Order by mostDeaths desc

-- Continents with highest death count
Select continent, MAX(total_deaths) as mostDeaths
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location not like '%income%'
Group by continent
Order by mostDeaths desc

-- Global Data
-- Get rid of selecting locations to have global data.
Select date, (SUM(total_cases) + SUM(new_cases)) as globalCases, (SUM(total_deaths) + SUM(new_deaths)) as globalDeaths, 
	((SUM(total_deaths) + SUM(new_deaths))/(SUM(total_cases) + SUM(new_cases)))*100 as deathperc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Group by date
Order by 1, 2

-- CTE for Death_Percentage
With Death_Perc (Date, Global_Cases, Global_Deaths) as
(Select date, (SUM(total_cases) + SUM(new_cases)) as globalCases, (SUM(total_deaths) + SUM(new_deaths)) as globalDeaths
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Group by date
)

Select *, (Global_Deaths/Global_Cases)*100 as Death_Perc
FROM Death_Perc

Select death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER 
(Partition by death.location Order By death.location, death.date) as totalVac
FROM PortfolioProject..['CovidDeaths$'] death
JOIN PortfolioProject..['CovidVaccines$'] vac
	ON death.location = vac.location and
	death.date = vac.date
WHERE death.continent is not NULL and death.location NOT LIKE '%income%'
Order by 2,3

-- CTE
With PopulationVac (Continent, Location, Date, Population, New_Vaccinations, Total_Vaccinations)
as 
(Select death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER 
(Partition by death.location Order By death.location, death.date) as totalVac
FROM PortfolioProject..['CovidDeaths$'] death
JOIN PortfolioProject..['CovidVaccines$'] vac
	ON death.location = vac.location and
	death.date = vac.date
WHERE death.continent is not NULL and death.location NOT LIKE '%income%'
) 

Select *, (Total_Vaccinations/Population)*100 as Perc_Vaccinated
FROM PopulationVac

-- Temp Tables
DROP TABLE IF EXISTS #Perc_Vaccinated
CREATE TABLE #Perc_Vaccinated 
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime,
Population numeric,
New_Vaccinations bigint,
Total_Vaccinations bigint
)

INSERT INTO #Perc_Vaccinated
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER 
(Partition by death.location Order By death.location, death.date) as totalVac
FROM PortfolioProject..['CovidDeaths$'] death
JOIN PortfolioProject..['CovidVaccines$'] vac
	ON death.location = vac.location and
	death.date = vac.date
WHERE death.continent is not NULL and death.location NOT LIKE '%income%'

Select *, (Total_Vaccinations/Population)*100 as Perc_Vaccinated
FROM #Perc_Vaccinated

-- Creating View -- Storing data for visualization

Create View Percent_Vaccinated as
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER 
(Partition by death.location Order By death.location, death.date) as totalVac
FROM PortfolioProject..['CovidDeaths$'] death
JOIN PortfolioProject..['CovidVaccines$'] vac
	ON death.location = vac.location and
	death.date = vac.date
WHERE death.continent is not NULL and death.location NOT LIKE '%income%'

Create View Death_Percentage as
Select date, (SUM(total_cases) + SUM(new_cases)) as globalCases, (SUM(total_deaths) + SUM(new_deaths)) as globalDeaths, 
	((SUM(total_deaths) + SUM(new_deaths))/(SUM(total_cases) + SUM(new_cases)))*100 as deathperc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
Group by date

CREATE View Country_Death_Rate as
Select continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathperc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'

CREATE View Continent_Death_Rate as
Select continent, AVG((total_deaths/total_cases)*100) as deathperc
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
GROUP BY continent

CREATE View Country_Infected_Perc as
Select location, date, total_cases, population, (total_cases/population)*100 as hasCovid
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'

CREATE View Continent_Infected_Perc as
Select continent, MAX((total_cases/population)*100) as hasCovid
FROM PortfolioProject..['CovidDeaths$']
WHERE continent is not NULL and location NOT LIKE '%income%'
GROUP BY continent