---
id: runningtests
title: Running the test suite
---

The test suite can be run in two ways:

1. From the command line, by running `/preside> ./test.sh`
2. Through a browser, by running `/preside> ./support/tests/startserver.sh` 

Both methods require that you have [CommandBox](https://www.ortussolutions.com/products/commandbox) installed and in your path.

## Test database

Both methods also require that you have an empty test database accessible to the server running the code. The easiest way to do that is to have a local MySQL database and user created with the following credentials:

```
Host     : localhost
Port     : 3306
DB Name  : preside_test
User     : travis
Password : (empty)
```

An alternative database can be used by setting the following environment variables that should be made available to the running test suite:

```
PRESIDETEST_DB_HOST
PRESIDETEST_DB_PORT
PRESIDETEST_DB_NAME
PRESIDETEST_DB_USER
PRESIDETEST_DB_PASSWORD
```

## Be patient

On my well spec'd laptop, the full test suite takes around two minutes to complete. Expect for the suite to take a long time.

>>>>>> Use the Web browser based test suite runner to be able to pick and choose which tests to run, this will make a huge difference when focusing on a particular area of development.