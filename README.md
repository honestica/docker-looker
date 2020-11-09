# Summary

> Looker is a cloud-based business intelligence (BI) platform designed to explore and analyze data.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Summary](#summary)
- [Why](#why)
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

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Why

Own by Google, Looker can help both large and small companies glean value from their data.
With it, they can access a web-based interface where they can easily get real-time insights
on their operations via data analytics.

# How

# What

## Version

The current version is `looker-7.18.21.jar`.

## Repo organization

```bash
.
├── Dockerfile # the Docker Image
├── LICENSE
├── Notes.md # Explanations and usage for the current changes
├── README.md # Deprecated version
└── templates
    ├── looker_run.sh # Required script (find more info below)
    └── provision.yaml # Default config (find more info below)
```

The `looker_run.sh` file is mantory to run looker.
That's explain why the `CMD`.

The `provision.yaml` file allow to automatically charge config as the licence key, users, etc.
It's like the definition of a root user when you start using Looker.

> NB:
> - the password must contain at least 1 capital letter, 1 lowercase, 1 number & 1 special character.
> - for now beware with those data not encrypted or managed by a secret.

## Database (warning)

As it's recommanded by the documentation we are using an internal database.
The consequence is **we don't have a data persistancy**.
As the DB is generated when the service start, the Looker file cannot be properly mount in a PVC.

# Operations


## Download Looker & its dependencies

You first need a licence key:
```bash
Delivered to: xxx@lifen.fr
License Key: xxx
Date of Delivery: xx/xx/2020
```

You have to configure LICENSE and EMAIL variable

### Localhost port-foward

You have to ping an `httpS` endpoint.

# Useful links

* [Installing the Looker Application](https://docs.looker.com/setup-and-management/on-prem-install/installation)

