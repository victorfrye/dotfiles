# MARK: Git — repository management functions

function Reset-AllRepositories() {
  Get-AllRepositories | ForEach-Object { git init $_.FullName }
}

function Get-AllRepositories() {
  return (Get-ChildItem $env:DEVDRIVE -Attributes Directory+Hidden -ErrorAction SilentlyContinue -Filter '.\.git' -Recurse).Parent
}

function Clear-RepositoryBranches() {
  git branch --list `
  | Select-String -Pattern '^\*' -NotMatch `
  | Select-String -Pattern 'main' -NotMatch `
  | ForEach-Object { git branch -D $_.Line.Trim() }
}
