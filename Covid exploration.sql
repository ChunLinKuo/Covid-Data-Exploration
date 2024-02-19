--Looking at total cases vs total deaths
SELECT location, date, total_cases, total_deaths, 
       CAST(total_deaths AS decimal) / CAST(total_cases AS decimal)*100 AS death_rate 
FROM [ PorfolioProject].[dbo].[CovidDeaths$]
WHERE continent is not null
ORDER BY 1,2

--Looking at death rate for the United States
SELECT location, date, total_cases, total_deaths, 
       CAST(total_deaths AS decimal) / CAST(total_cases AS decimal)*100 AS death_rate 
FROM [ PorfolioProject].[dbo].[CovidDeaths$]
WHERE location LIKE '%states'
ORDER BY 1,2

--Looking at percentage of population got Covid
SELECT location, date, total_cases, population,
       CAST(total_cases AS decimal) / CAST(population AS decimal)*100 AS PerctangePopulationInfected
FROM [ PorfolioProject].[dbo].[CovidDeaths$]
WHERE continent is not null
ORDER BY 1,2

--Highest infected rate among countries
SELECT location, population,MAX(total_cases)AS HeighestInfectionCount,
MAX((CAST(total_cases AS decimal)/CAST(population AS decimal))*100) AS PercentPopulationInfected
FROM [ PorfolioProject].[dbo].[CovidDeaths$]
WHERE continent is not null
GROUP BY Location,Population
ORDER BY PercentPopulationInfected DESC


--Showing countries with highest death count per population
SELECT location,MAX(CAST(total_deaths AS int)) AS highestdeaths
FROM [ PorfolioProject].[dbo].[CovidDeaths$]
WHERE continent is null
GROUP BY location 
ORDER BY highestdeaths DESC

--Showing the highest death rate and death counts among continents
SELECT continent, MAX(CAST(total_deaths AS decimal)) AS totaldeathscount, MAX(CAST(total_deaths AS decimal) / CAST(population AS decimal)) *100 AS deathrate
FROM [ PorfolioProject].[dbo].[CovidDeaths$]
WHERE continent is not null
GROUP BY continent
ORDER BY deathrate DESC

--Total numbers per day
SELECT date, SUM(CAST(new_cases AS int)) AS totalcases, SUM(CAST(new_deaths AS int)) AS totaldeaths,
       CASE WHEN SUM(CAST(new_cases AS int)) = 0 THEN NULL
            ELSE SUM(CAST(new_deaths AS int)) / NULLIF(SUM(CAST(new_cases AS int)), 0) * 100
       END AS deathrate
FROM [ PorfolioProject].[dbo].[CovidDeaths$]
GROUP BY date
ORDER BY date

--Join function
SELECT *
FROM [ PorfolioProject].[dbo].[CovidDeaths$] AS DEA
JOIN [ PorfolioProject].[dbo].[Covidvaccination$] AS VAC ON DEA.location =VAC.location AND DEA.date=VAC.date
WHERE dea.continent is not null

--Vaccination rate
SELECT dea.continent, SUM(CAST(vac.new_vaccinations as decimal)) / MAX(CAST(dea.population as decimal)) AS vaccination_rate
FROM [ PorfolioProject].[dbo].[CovidDeaths$] AS DEA
JOIN [ PorfolioProject].[dbo].[Covidvaccination$] AS VAC ON DEA.location =VAC.location AND DEA.date=VAC.date
WHERE dea.continent is not null  
GROUP BY dea.continent

--Partition by
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(convert(int,vac.new_vaccinations))OVER(partition by dea.location ORDER BY dea.location,dea.date) AS rollingpeoplevaccination
FROM [ PorfolioProject].[dbo].[CovidDeaths$] AS DEA
JOIN [ PorfolioProject].[dbo].[Covidvaccination$] AS VAC ON DEA.location =VAC.location AND DEA.date=VAC.date
WHERE dea.continent is not null 
ORDER BY 2,3

--USE CTE
WITH population_vs_vaccination (Continent,location,date,population,new_vacinations,rollingpeoplevaccination)
AS
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(convert(int,vac.new_vaccinations))OVER(partition by dea.location ORDER BY dea.location,dea.date) AS rollingpeoplevaccination
FROM [ PorfolioProject].[dbo].[CovidDeaths$] AS DEA
JOIN [ PorfolioProject].[dbo].[Covidvaccination$] AS VAC ON DEA.location =VAC.location AND DEA.date=VAC.date
WHERE dea.continent is not null 
)
SELECT*,CAST(rollingpeoplevaccination as decimal)/CAST(population as decimal) *100 as vaccination_rate
FROM population_vs_vaccination

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_Vaccinations numeric,
    RollingPeopleVaccination numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccination
FROM [ PorfolioProject].[dbo].[CovidDeaths$] AS DEA
JOIN [ PorfolioProject].[dbo].[Covidvaccination$] AS VAC ON DEA.location = VAC.location AND DEA.date = VAC.date
WHERE dea.continent IS NOT NULL

SELECT *, CAST(RollingPeopleVaccination AS decimal) / CAST(Population AS decimal) * 100 AS VaccinationRate
FROM #PercentPopulationVaccinated

--View
CREATE VIEW PercetPopulationVaccinated as
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(convert(int,vac.new_vaccinations))OVER(partition by dea.location ORDER BY dea.location,dea.date) AS rollingpeoplevaccination
FROM [ PorfolioProject].[dbo].[CovidDeaths$] AS DEA
JOIN [ PorfolioProject].[dbo].[Covidvaccination$] AS VAC ON DEA.location =VAC.location AND DEA.date=VAC.date
WHERE dea.continent is not null 

SELECT *
FROM PercetPopulationVaccinated

--Check infected rate, vaccination rate and death rate per continent.
WITH VaccinationRate AS (
    SELECT dea.continent, SUM(CAST(vac.new_vaccinations AS decimal)) / MAX(CAST(dea.population AS decimal)) AS vaccination_rate
    FROM [ PorfolioProject].[dbo].[CovidDeaths$] AS DEA
    JOIN [ PorfolioProject].[dbo].[Covidvaccination$] AS VAC ON DEA.location = VAC.location AND DEA.date = VAC.date
    WHERE dea.continent IS NOT NULL  
    GROUP BY dea.continent
),
InfectedRate AS (
    SELECT continent,
	SUM(CAST(total_cases AS decimal)) AS total_cases,
	SUM(CAST(population AS decimal)) AS total_population,
	CAST(SUM(CAST(total_cases AS decimal)) AS decimal) / NULLIF(SUM(CAST(population AS decimal)), 0) * 100 AS PercentagePopulationInfected
    FROM [ PorfolioProject].[dbo].[CovidDeaths$]
    GROUP BY continent
),
DeathRate AS (
    SELECT continent, MAX(CAST(total_deaths AS decimal)) AS totaldeathscount, MAX(CAST(total_deaths AS decimal) / CAST(population AS decimal)) * 100 AS deathrate
    FROM [ PorfolioProject].[dbo].[CovidDeaths$]
    WHERE continent IS NOT NULL
    GROUP BY continent
)
SELECT VR.continent,VR.vaccination_rate,IR.PercentagePopulationInfected,DR.deathrate
FROM VaccinationRate AS VR
JOIN InfectedRate AS IR ON VR.continent = IR.continent
JOIN DeathRate AS DR ON VR.continent = DR.continent

