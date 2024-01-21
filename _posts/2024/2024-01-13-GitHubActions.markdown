---
title:  "GitHub Actions for Jar file deployment"
categories: github
---

This is a memo for a [GitHub project](https://github.com/ntamagawa/sumpdata) that I'm planning to do CI/CD into an AWS instance (likely Lightsail AL2023).

Reference: [CI/CD for Java Maven using GitHub Actions](https://medium.com/@alexander.volminger/ci-cd-for-java-maven-using-github-actions-d009a7cb4b8f)

## CI/CD Flow

1. On PR merge to the `main` branch, run a GitHub action to create a Jar file (aka artifact). 
2. Upload the artifact - meaning make the artifact public
3. Download the artifact from GitHub

This flow can be done more sophisticated way using a CI/CD tool, but for my purpose, automatically packaging a jar then download using curl is good enough.

## GitHub action
Below action set up JDK 21, build the package using Maven, then "upload" the jar file.
```yml
name: Package Jar with Maven

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    - name: Set up JDK 21
      uses: actions/setup-java@v3
      with:
        java-version: '21'
        distribution: 'temurin'
        cache: maven
    - name: Build with Maven
      run: mvn -B package --file pom.xml -DskipTests

    # https://medium.com/@alexander.volminger/ci-cd-for-java-maven-using-github-actions-d009a7cb4b8f
    - name: Upload jar
      run: mkdir staging && cp target/sumpdata-*.jar staging
    - uses: actions/upload-artifact@v4
      with:
        name: Package
        path: staging
      
```
Here, the concept of "upload" is a little confusing. What the GitHub action [upload-artifact](https://github.com/actions/upload-artifact) does is to "copy" the jar file to a publicly accessible folder.

## Curl Command to Download Jar
Use GitHub REST API, in particular, [GitHub Actions Artifact](https://docs.github.com/en/rest/actions/artifacts?apiVersion=2022-11-28) endpoint.

### List artifacts
```bash
curl https://api.github.com/repos/<Owner>/<Repo>/actions/artifacts
```
Output
```json
{
  "total_count": 2,
  "artifacts": [
    {
      "id": 1167583720,
      "node_id": "MDg6QXJ0aWZhY3QxMTY3NTgzNzIw",
      "name": "Package",
      "size_in_bytes": 58991355,
      "url": "https://api.github.com/repos/ntamagawa/sumpdata/actions/artifacts/1167583720",
      "archive_download_url": "https://api.github.com/repos/ntamagawa/sumpdata/actions/artifacts/1167583720/zip",
      "expired": false,
      "created_at": "2024-01-13T22:38:33Z",
      "updated_at": "2024-01-13T22:38:33Z",
      "expires_at": "2024-04-12T22:38:10Z",
      "workflow_run": {
        "id": 7515265725,
        "repository_id": 705318802,
        "head_repository_id": 705318802,
        "head_branch": "main",
        "head_sha": "fe3baccee31adbc74b1999c8c3e5c46709bd5ca7"
      }
    },
    {
      "id": 1167559585,
      "node_id": "MDg6QXJ0aWZhY3QxMTY3NTU5NTg1",
      "name": "Package",
      "size_in_bytes": 58991346,
      "url": "https://api.github.com/repos/ntamagawa/sumpdata/actions/artifacts/1167559585",
      "archive_download_url": "https://api.github.com/repos/ntamagawa/sumpdata/actions/artifacts/1167559585/zip",
      "expired": false,
      "created_at": "2024-01-13T21:52:17Z",
      "updated_at": "2024-01-13T21:52:17Z",
      "expires_at": "2024-04-12T21:51:57Z",
      "workflow_run": {
        "id": 7515043712,
        "repository_id": 705318802,
        "head_repository_id": 705318802,
        "head_branch": "main",
        "head_sha": "fe3baccee31adbc74b1999c8c3e5c46709bd5ca7"
      }
    }
  ]
}
```
Note: It seems that there's no access privilege is required for a public repo.

### Download the artifact
I take the `archive_download_url` from the latest artifact, then download as a zip file.

```bash
curl -L -o artifact.zip \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <github_token>" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
https://api.github.com/repos/ntamagawa/sumpdata/actions/artifacts/1167559585/zip
```

Note that you need to generate your own GitHub personal access tokens. See [Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).
For the above REST API `repos/.../actions/artifacts/...`, a `Read` access is required. [This page ](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#deployments)lists what permission is required for REST APIs.


Then, unzip the file which contains the generated jar file.
```bash
unzip  artifact.zip
```

