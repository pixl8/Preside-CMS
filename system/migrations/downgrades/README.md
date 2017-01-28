Downgrade migration scripts
===========================

Any CFC files in this directory will have their "Run" method invoked when PresideCMS is being downgraded to a version less than the version indicated by the name of the CFC file. i.e. expect to see filenames such as 0-10-34.cfc or 10-7-2.cfc.