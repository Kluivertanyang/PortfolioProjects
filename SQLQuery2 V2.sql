



Select *
From PortfolioProject..CovidDeath
Where continent is not null
order by 3,4


--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4



--Select data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeath
order by 1,2


-- Looking at Total cases Vs Total Deaths
-- shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS Deathpercentage
From PortfolioProject..CovidDeath
where location like '%states%'
order by 1,2


-- Looking at the Total cases Vs Population
-- Shows what population got Covid 

Select Location, date, population, total_cases, (total_cases/population)*100 AS percentagepopulationinfected
From PortfolioProject..CovidDeath
where location like '%states%'
order by 1,2

--Looking at some countries with Highest infection rate compared to pupolation

Select Location, population, MAX(total_cases) as HighestinfectionCount, MAX((total_cases/population))*100 as 
 percentagepopulationinfected
From PortfolioProject..CovidDeath
--WHERE location LIKE '%states%'
Group by Location, Population
order by PercentagepopulationInfected desc

-- Showing countries with highest death Count per population 

Select Location,  MAX(cast(total_deaths as int)) as TotaltDeathCount
From PortfolioProject..CovidDeath
--WHERE location LIKE '%states%'
Where continent is not null
Group by Location
order by TotaltDeathCount desc
 
 -- Lets's break down by Continent

 
Select continent,  MAX(cast(total_deaths as int)) as TotaltDeathCount
From PortfolioProject..CovidDeath
--WHERE location LIKE '%states%'
Where continent is not null
Group by continent
order by TotaltDeathCount desc


--Global 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeath
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3
 

 -- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


--TEMP TABLE 

DROP Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating view to store data for later visualizations

Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by
dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select location, MAX(RollingPeopleVaccinated) as TotalVaccinated
From PercentPopulationVaccinated
group by location