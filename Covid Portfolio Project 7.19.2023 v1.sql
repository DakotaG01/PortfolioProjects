SELECT *
FROM CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

SELECT Location, Date, Total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you contract covid in your country

SELECT Location, Date, Total_cases, total_deaths, (Total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2


--Looking at the total cases vs the population
--Shows what percentage og populatioin got covid

SELECT Location, Date, population, Total_cases, (Total_cases/population)*100 AS PopulationInfectedPercentage
FROM CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2


--Looking at countries with highest infection rate compared to population

SELECT Location, population, MAX(Total_cases) AS HighestInfectionCount, MAX((Total_cases/population))*100 AS PopulationInfectedPercentage
FROM CovidDeaths
GROUP BY Location, Population
ORDER BY PopulationInfectedPercentage DESC


--Showing the countries with the highest death count per population

SELECT Location, MAX(cast(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC


--LET'S BREAK THINGS DOWN BY CONTINENT

--Showing the continents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



--Global Numbers

SELECT date, SUM(new_cases)
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, SUM(cast(new_deaths AS INT))/
	SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



--Total global cases, deaths, and death percentage

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, SUM(cast(new_deaths AS INT))/
	SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



--Vaccinations Table

SELECT *
FROM CovidVaccinations


--Joining the CovidDeaths and CovidVaccinations Tables

SELECT *
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date


--Looking at total population vs vaccinations


SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3


--Adding running daily total of vaccinations

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations AS INT)) OVER 
	(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxxed
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3


--USING CTE

WITH PopVsVax (Continent, Locaiton, Date, Population,new_vaccinations, RollingPeopleVaxxed)
AS 
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations AS INT)) OVER 
	(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxxed
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaxxed/population)*100
FROM PopVsVax


--Temp Table
--Add DROP TABLE IF EXISTS at the beginning because if you make alterations, you do not have to delete the
--temp table each time. This line does that first thing.

DROP TABLE IF EXISTS #PercentPopulationVaxxed
CREATE TABLE #PercentPopulationVaxxed
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric, 
new_vaccinations numeric,
rollingpeoplevaxxed numeric,
)

INSERT INTO #PercentPopulationVaxxed
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations AS INT)) OVER 
	(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxxed
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL

SELECT *, (RollingPeopleVaxxed/population)*100
FROM #PercentPopulationVaxxed


--Creating view to store data for later visualizations


CREATE VIEW PercentPopulationVaxxed AS 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations AS INT)) OVER 
	(PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxxed
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON deaths.location = vax.location 
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL


SELECT *
FROM PercentPopulationVaxxed