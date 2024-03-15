select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

-- a) Looking at Total Cases VS Total Deaths

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100
from PortfolioProject..CovidDeaths
order by 1,2

-- b) Specifying the Country
----Showing the likelihood of dying if you got infected in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%stat%'
order by 1,2

--Looking at Total Cases VS Population
----Shows what percentage of the population gets covid
select location, date, total_cases, population, (total_cases/population)*100 as CasesPercentage
from PortfolioProject..CovidDeaths
where location like '%gyp%'
order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population
select location, population, max(total_cases) TotalCases, max(total_cases/population)*100 as CasesPercentage
from PortfolioProject..CovidDeaths
group by location, population
order by 4 desc

--Countries with the highest death count per population
----'Cast' is for converting the varchar type column into int as the arrangement was not correct
----We added 'where continent is not null' because in this table when the continents where shown in the data as a country because of a shift in the continent name when it is blank a [and this is a special error that varies from a set of data to another]
select location, MAX(cast(total_deaths as int)) as HighestDeaths
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by HighestDeaths desc
--Continent
select continent, MAX(cast(total_deaths as int)) as HighestDeaths
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by HighestDeaths desc

--Global Numbers
select date, sum(new_cases) TotalCases, sum(cast(new_deaths as int)) TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases) * 100 DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2 desc
--Or we can remove the date altogether if we want just one global number

--Looking at Total Population VS Vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
--sum(cast(vac.new_vaccinations as int))
sum(convert(int, vac.new_vaccinations)) --The Same--
over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--The over partition by is important as it shows what the summations will be based on and without it, it will return an error anyway
--We put inside the over and order by location and date so that it keeps adding up in the summation total until the end instead of puttin the whole total of the location in all the cells
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3
--This is where the role of the CTE or the Temp table comes in as here we need to divid the sum of the new vaccinations [The variable: RollingPeopleVaccinated] over the population. But, we can't use a variable we created that way unless it is an actual column so:
with ForRPVvsPopulation (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) --The number of columns here must be the same as those of the 'select' below--
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3    "This order by returns an error in CTE"
)
select *, (RollingPeopleVaccinated/population)*100 as VacToPopulation
from ForRPVvsPopulation

--OR--

create table #PercentPopulationVaccinated
(continent nvarchar(255), --new and almost the same datatypes--
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/population)*100 as VacToPopulation
from #PercentPopulationVaccinated

--Remember--
Drop table if exists #PercentPopulationVaccinated --if need be

--Create View
--It's permenant and almost the same as the table--dosn't accept order by
--found in 'views'
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null

select *
from PercentPopulationVaccinated
--Now Save on GitHub--