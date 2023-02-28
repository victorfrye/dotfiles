# Oh My Posh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression

# Git - These functions allow for management of all Git Repositories
function Initialize-AllRepositories() {
    $RepositoryDirectories = Get-AllRepositories
  
    foreach ($Repo in $RepositoryDirectories) {
      git init $Repo.FullName
    }
  }
  
  function Get-AllRepositories() {
    return (Get-ChildItem $env:REPOHOME -Attributes Directory+Hidden -ErrorAction SilentlyContinue -Filter ".\.git" -Recurse).Parent
  }
  
  # Docker - These functions include general Docker commands that might be useful
  function Clear-Docker { docker image prune -a --filter "until=12h"; docker system prune }
  
  ## Oracle Containers - These functions allow management of a local Oracle virtual container using Docker
  function New-OracleContainer { docker run -d --name local_oracle -p 49160:22 -p 49161:1521 wnameless/oracle-xe-11g-r2 }
  function Start-OracleContainer { docker start local_oracle }
  function Stop-OracleContainer { docker stop local_oracle }
  function Remove-OracleContainer { docker rm local_oracle }
  
  ## Postgres Containers These functions allow management of a local PostgreSQL virtual container using Docker
  function New-PostgresContainer { docker run -d --name local_postgres -p 5432:5432 postgres:11.1 }
  function Start-PostgresContainer { docker start local_postgres }
  function Stop-PostgresContainer { docker stop local_postgres }
  function Remove-PostgresContainer { docker rm local_postgres }
  
  ## MS SQL Server Containers - These functions allow management of a local MSSQL virtual container using Docker
  function New-MsSqlContainer { docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Go0dPassword" -d --name local_mssql -p 1433:1433 mcr.microsoft.com/mssql/server:2017-latest }
  function Start-MsSqlContainer { docker start local_mssql }
  function Stop-MsSqlContainer { docker stop local_mssql }
  function Remove-MsSqlContainer { docker rm local_mssql }
  
  ## AMQ Containers - These functions allow management of a local ActiveMQ virtual container using Docker
  function New-AmqContainer { docker run -d --name local_amq  -p 61616:61616 -p 8161:8161 rmohr/activemq }
  function Start-AmqContainer { docker start local_amq }
  function Stop-AmqContainer { docker stop local_amq }
  function Remove-AmqContainer { docker rm local_amq }
  function Open-AmqContainer { open http://localhost:8161/admin }
  
  ## Redis Containers - These functions allow management of a local Redis virtual container using Docker
  function New-RedisContainer { docker run -d --name local_redis  -p 6379:6379 redis }
  function Start-RedisContainer { docker start local_redis }
  function Stop-RedisContainer { docker stop local_redis }
  function Remove-RedisContainer { docker rm local_redis }
  
  # OpenShift - These functions allow for connection management to Openshift servers
  function Connect-Openshift([switch] $Production) {
  
    if ($Production) {
      oc login https://somedomain.com:6443 -u="$env:USERNAME"
    }
    else {
      oc login https://somedomain.com:6443 -u="$env:USERNAME"
    }
  }
  function Disconnect-Openshift() { oc logout }
  
  # Java - These functions allow for JDK version management
  function Set-JavaVersion([int] $Version) {
  
    if (-NOT($Version)) {
      $env:JAVA_HOME = $env:JDK_17
      Write-Host "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
      return
    }
  
    switch ($Version) {
      8 {
        $env:JAVA_HOME = $env:JDK_8
        Write-Host "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
        break
      }
      11 {
        $env:JAVA_HOME = $env:JDK_11
        Write-Host "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
        break
      }
      16 {
        $env:JAVA_HOME = $env:JDK_16
        Write-Host "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
        break
      }
      17 {
        $env:JAVA_HOME = $env:JDK_17
        Write-Host "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
        break
      }
      Default { Write-Host "No JDK configured for version $PSItem... Aborted." }
    }
  }