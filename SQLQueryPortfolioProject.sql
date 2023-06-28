--Update PortfolioProject..CovidDeathsCSV
--SET continent = NULLIF(continent,'')
--where continent = ''

Select *
From PortfolioProject..CovidDeathsCSV
where location = 'world'
order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeathsCSV

-- Total Cases vs Total Deaths per Country
-- Shows likelihood of dying if you get covid in Canada

SELECT
    Location,
    Date,
    total_cases,
    total_deaths,
    (CAST(total_deaths AS DECIMAL(20, 2)) / CAST(total_cases AS DECIMAL(20, 2))) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsCSV
where location = 'Canada'
and continent is not null
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got COVID

SELECT
    Location,
    Date,
    total_cases,
    Population,
    (CAST(total_cases AS DECIMAL(20, 2)) / CAST(population AS DECIMAL(20, 2))) * 100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeathsCSV
where location = 'Canada'
order by 1,2

--Countries with highest infection rate compared to population

SELECT
    Location,
    Population,
    MAX(total_cases) as HighestInfectionCount,
    MAX(CAST(total_cases AS DECIMAL (20,2))/ CAST(population AS DECIMAL(20, 2)))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeathsCSV
--where location = 'Canada'
Group by Location, Population
order by 4 desc


-- Countries with highest death count per population

SELECT
    Location,
    MAX(CAST(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeathsCSV
--where location = 'Canada'
where continent is not null
Group by Location
order by TotalDeathCount desc


-- BY CONTINENT

-- Continents with highest death count

SELECT
    continent,
    MAX(CAST(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeathsCSV
--where location = 'Canada'
where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

SELECT
    Date,
    SUM(new_cases) as total_new_cases,
	SUM(new_deaths) as total_new_deaths,
	CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(new_deaths) * 100.0 / SUM(new_cases)
    END AS DeathPercentage
FROM PortfolioProject..CovidDeathsCSV
where continent is not null
Group By Date
order by 1,2

SELECT
    SUM(new_cases) as total_new_cases,
	SUM(new_deaths) as total_new_deaths,
	SUM(CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(new_deaths) * 100.0 / SUM(new_cases)
    END) AS DeathPercentage
FROM PortfolioProject..CovidDeathsCSV
where continent is not null
Group By Date
order by total_new_cases, total_new_deaths


-- JOINING DEATHS AND VACCINATIONS TABLES

Select *
From PortfolioProject..CovidDeathsCSV dea
Join PortfolioProject..CovidVaccinationsCSV vac
	On dea.location = vac.location
	and dea.date = vac.date

--Looking at Total Population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) RollingPeopleVaccinated
From PortfolioProject..CovidDeathsCSV dea
Join PortfolioProject..CovidVaccinationsCSV vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

--USING CTE

With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.Date) RollingPeopleVaccinated
From PortfolioProject..CovidDeathsCSV dea
Join PortfolioProject..CovidVaccinationsCSV vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (CAST(RollingPeopleVaccinated as bigint)/CAST(Population as bigint))*100
FROM PopVsVac