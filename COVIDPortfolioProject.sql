-- Update PortfolioProject..CovidDeathsCSV
UPDATE PortfolioProject..CovidDeathsCSV
SET continent = NULLIF(continent, '')
WHERE continent = ''

-- Select all rows from PortfolioProject..CovidDeathsCSV where location is 'world' and order by column 3 and 4
SELECT *
FROM PortfolioProject..CovidDeathsCSV
WHERE location = 'world'
ORDER BY 3, 4

-- Select specific columns from PortfolioProject..CovidDeathsCSV where location is 'world'
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeathsCSV

-- Calculate death percentage in Canada based on total cases and total deaths
SELECT
    Location,
    Date,
    total_cases,
    total_deaths,
    (CAST(total_deaths AS DECIMAL(20, 2)) / CAST(total_cases AS DECIMAL(20, 2))) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeathsCSV
WHERE location = 'Canada'
AND continent IS NOT NULL
ORDER BY 1, 2

-- Calculate the percentage of population infected with COVID in Canada
SELECT
    Location,
    Date,
    total_cases,
    Population,
    (CAST(total_cases AS DECIMAL(20, 2)) / CAST(population AS DECIMAL(20, 2))) * 100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeathsCSV
WHERE location = 'Canada'
ORDER BY 1, 2

-- Get countries with the highest infection rate compared to population
SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(CAST(total_cases AS DECIMAL(20, 2)) / CAST(population AS DECIMAL(20, 2))) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeathsCSV
GROUP BY Location, Population
ORDER BY 4 DESC

-- Get countries with the highest death count per population
SELECT
    Location,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeathsCSV
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Get continents with the highest death count
SELECT
    continent,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeathsCSV
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Get global numbers for new cases, new deaths, and death percentage
SELECT
    Date,
    SUM(new_cases) AS total_new_cases,
    SUM(new_deaths) AS total_new_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(new_deaths) * 100.0 / SUM(new_cases)
    END AS DeathPercentage
FROM PortfolioProject..CovidDeathsCSV
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY 1, 2

-- Get total new cases, total new deaths, and death percentage
SELECT
    SUM(new_cases) AS total_new_cases,
    SUM(new_deaths) AS total_new_deaths,
    SUM(CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(new_deaths) * 100.0 / SUM(new_cases)
    END) AS DeathPercentage
FROM PortfolioProject..CovidDeathsCSV
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY total_new_cases, total_new_deaths

-- Join deaths and vaccinations tables
SELECT *
FROM PortfolioProject..CovidDeathsCSV dea
JOIN PortfolioProject..CovidVaccinationsCSV vac
    ON dea.location = vac.location
    AND dea.date = vac.date

-- Get total population vs vaccinations
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathsCSV dea
JOIN PortfolioProject..CovidVaccinationsCSV vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Using CTE for population vs vaccinations
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeathsCSV dea
    JOIN PortfolioProject..CovidVaccinationsCSV vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (CAST(RollingPeopleVaccinated AS BIGINT) / CAST(Population AS BIGINT)) * 100
FROM PopVsVac;
