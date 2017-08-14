---
id: preparing-for-an-upgrade
title: Preparing for an upgrade
---

# Preparing for an upgrade

Whenever you are upgrading Preside, you should bear in mind that you are upgrading an underlying platform and that your application will require testing for any conflicting changes. With that in mind, we urge you to always test both:

* performing the upgrade
* application functionality after the upgrade

Always read the [release notes](https://www.preside.org/release-notes.html) and [[upgradenotes|upgrade notes]] for all the releases between your current version and the target version to be sure that you are fully aware of what the upgrade consists of. This will help you plan your testing and prepare you for any large changes that might otherwise cause a surprise.

## Maintenance mode

We recommend that you always use Maintenance Mode for upgrading Preside (see [[customerrorpages]]). This ensures that live traffic to the site does not affect the upgrade process and that the end-user experience is as smooth as it can be. It will also make sure that any error messages / warnings / SQL upgrade messages that arise from the upgrade will *not* be visible to your users.

## Database upgrades

Upgrades that require changes to the database deserve special care and attention. The Preside platform has the ability to automatically synchronize your database schema but the default setting is to turn this _off_ except for local development environments. This is controlled through settings in `Config.cfc`:

```
settings.syncDb     = true;
settings.autoSyncDb = false;
```

When `settings.syncDb` is set to `false`, the application will make **no attempt** to synchronise the database. You will be responsible for maintaining your database schema. The default value for this setting is `true`.

If `settings.syncDb` is set to `true` and `settings.autoSyncDb` is set to `false`, the application will create an upgrade SQL script that you can then run directly on your database. The script will be saved at `/{webroot}/logs/sqlupgrade.sql` and a message will appear informing you that it has been generated. It is strongly advised to check the content of the script before running it against your database. Once the script has been run, you can reload your application again and you are all done.

Finally, if `settings.syncDb` is set to `true` and `settings.autoSyncDb` is set to `true`, the application will directly modify your database's schema during the application reload/startup process. We recommend this for local/dev environments only.


### Schema sync script generator extension

You may also wish to use our [DB Upgrade Script Generator](https://github.com/pixl8/preside-ext-dbupgradescriptgenerator) extension. This allows you to generate an upgrade script ahead of performing your upgrade. The extension provides an admin UI that allows you to enter the details of the target database before generating the script. 

This process should be run from either a local or testing server that is running the **exact preside version and application version** that your live server will be running **after the upgrade**. 

This reduces the time to perform your upgrade in your live environment, especially for sites with large databases. It can also be used to help test upgrades by being able to run the script against a recent backup of the live database, etc.
