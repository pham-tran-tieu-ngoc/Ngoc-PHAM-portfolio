select location, date, total_cases, new_cases, total_deaths, population
from [Portfolio Project].dbo.CovidDeaths
order by 1,2

--looking at total cases vs total deaths

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from [Portfolio Project].dbo.CovidDeaths
where location like '%viet%'
order by 1,2

--looking at total cases vs population

Select location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
from [Portfolio Project].dbo.CovidDeaths
where location like '%viet%'
order by 1,2

--looking at new cases vs population

Select location, date, population, new_cases, (new_cases/population)*100 as NewCasesPercentage
from [Portfolio Project].dbo.CovidDeaths
where location like '%viet%'
order by 1,2

--looking at countries with highest infection rate compared to population

Select location, population, Max(total_cases) as HighestInfectionCount, 
	Max((total_cases/population)*100) as PercentPopulationInfected
from [Portfolio Project].dbo.CovidDeaths
Group by location, population
order by PercentPopulationInfected desc

--where is my country in the above chart?

SELECT location, Ranking
FROM (
    SELECT location, population, Max(total_cases) as HighestInfectionCount, 
           Max((total_cases/population)*100) as PercentPopulationInfected,
           DENSE_RANK() OVER (ORDER BY Max((total_cases/population)*100) DESC) AS Ranking
    FROM [Portfolio Project].dbo.CovidDeaths
    GROUP BY location, population
) AS Rankings
WHERE location = 'Vietnam';

-- showing countries with highest death count per population

Select location, max(total_deaths) as TotalDeathCount
from [Portfolio Project].dbo.CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

Select location, population, Max(total_deaths) as TotalDeathCount, 
	Max((total_deaths/population)*100) as PercentDeathperPopulation
from [Portfolio Project].dbo.CovidDeaths
where continent is not null
Group by location, population
order by PercentDeathperPopulation desc

--BREAK DOWN BY CONTINENTS

Select continent, Max(total_deaths) as TotalDeathCount
from [Portfolio Project].dbo.CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc

--showing continents with highest death count per population

Select continent, Max(total_deaths) as TotalDeathCount,
	Max((total_deaths/population)*100) as PercentDeathperPopulation
from [Portfolio Project].dbo.CovidDeaths
where continent is not null
Group by continent
order by PercentDeathperPopulation desc

--GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN NULL 
        ELSE SUM(new_deaths)/SUM(new_cases)*100 
    END AS DeathPercentage
FROM [Portfolio Project].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_cases;

--Looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccination
from [Portfolio Project].dbo.CovidDeaths dea
join [Portfolio Project].dbo.CovidVacination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--which countries still vaccinating in 2023

SELECT DISTINCT location,
	sum(new_vaccinations) over (partition by location order by location) as CumulativeVaccination
FROM [Portfolio Project].dbo.CovidVacination
WHERE new_vaccinations IS NOT NULL
	and year(date) = 2023
	and continent is not null
order by 1

-- use CTE

With PopvsVav (continent, location, date, population, new_vaccinations, CumulativeVaccination)
as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as CumulativeVaccination
from [Portfolio Project].dbo.CovidDeaths dea
join [Portfolio Project].dbo.CovidVacination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (CumulativeVaccination/population)*100 as PercentageCumulativeVaccination
from PopvsVav
order by 2,3

-- TEMP TABLE

Drop table if exists #PercentVaccinated
CREATE TABLE #PercentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccination numeric
)

INSERT INTO #PercentVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		AS cumulative_vaccination
FROM [Portfolio Project].dbo.CovidDeaths dea
JOIN [Portfolio Project].dbo.CovidVacination vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (cumulative_vaccination/population)*100 AS PercentageCumulativeVaccination
FROM #PercentVaccinated
where continent is not null
order by 2,3 

-- Create view to store data for visualization

;DROP VIEW IF EXISTS PercentVaccinated;
GO

CREATE VIEW PercentVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
        AS cumulative_vaccination
FROM [Portfolio Project].dbo.CovidDeaths dea
JOIN [Portfolio Project].dbo.CovidVacination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT * FROM sys.views WHERE name = 'PercentVaccinated';