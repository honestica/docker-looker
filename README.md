# Summary

> Looker is a cloud-based business intelligence (BI) platform designed to explore and analyze data.

- [Summary](#summary)
- [How](#how)
- [What](#what)
  - [Version](#version)
  - [Repo organization](#repo-organization)
  - [Docker image base](#docker-image-base)
  - [Database (warning)](#database-warning)
- [Operations](#operations)
  - [Download Looker & its dependencies](#download-looker--its-dependencies)
  - [Localhost port-foward](#localhost-port-foward)
- [Useful links](#useful-links)

# What

## Purpose

This docker image is made to be run in Kubernete with the helm chart looker located at https://github.com/honestica/lifen-charts.

## Version

The current version is `looker-7.20.29.jar`.

## Repo organization

```bash
.
├── docker     # Directory which contains all pre-requisite to build docker image
├── LICENSE
├── Makefile
├── README.md
├── scripts    # Directory which contains scripts use by `Makefile`
└── spec       # Directory which contains tests
```


## Database (warning)

By default an internal database is used and is not persisted by default. Check the helm chart for a production usage.

# Operations


## Download Looker & its dependencies

You first need a licence key:
```bash
Delivered to: xxx@lifen.fr
License Key: xxx
Date of Delivery: xx/xx/2020
```

You have to configure LICENSE and EMAIL variable to be able to build the docker image.

### Localhost port-foward

You have to ping an `httpS` endpoint.

# Useful links

* [Installing the Looker Application](https://docs.looker.com/setup-and-management/on-prem-install/installation)
