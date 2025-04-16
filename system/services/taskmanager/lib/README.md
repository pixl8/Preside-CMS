# Cron-Utils Preside Build

We had OSGi issues with the source cron-utils package. Essentially down to SLF4J dependencies. This custom jar build
is built using our fork of the project found here:

https://github.com/pixl8/cron-utils/tree/preside-patched-cron-utils (preside-patched-cron-utils branch)

`mvn package` was then run from the root of this project to produce the jar file that was copied into this directory (and renamed).

