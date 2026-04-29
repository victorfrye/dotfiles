# MARK: Docker

function Clear-Docker { docker image prune -a --filter 'until=12h'; docker system prune }
