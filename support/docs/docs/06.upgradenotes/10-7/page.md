---
id: 10-7-upgrade-notes
title: Upgrade notes for 10.6 -> 10.7
---

## General notes

The **10.7.0** release introduces a handful of new features that warrant some attention during upgrades. In particular:

* The introduction of [[drafts|drafts]]
* The introduction of the [[rulesengine|rules engine framework]]
* Integration of the **preside-ext-taskmanager** extension into core (see [[taskmanager]])

>>>>> Please ensure that you have read and understood the general [[preparing-for-an-upgrade]] notes that apply to any Preside upgrade.

&nbsp;
>>>>>> We recommend upgrading directly to **10.8.0** if possible as this is a more-or-less straight forward upgrade from 10.7.0 and brings a lot of improvements. If you do opt to upgrade directly to **10.8.0**, the notes below are still relevent and should be read thoroughly.



## Preparing for upgrade

### Drafts

The new draft system brought around some fundamental database schema changes with regards to _versioning_. These changes require a data upgrade script to run and this will run as part of the application reload. To prepare for upgrade:

* Check for large version database tables
* Test the upgrade on a non-live version of the application that is using a restored backup of live data

#### Large version tables

**Important**: If you have version tables with a large number of rows, you should consider cleaning that data up and ensuring that your application is only making version changes when necessary **before running the Preside upgrade**. You can see database table sizes in MySQL with:

```sql
select   table_name
       , round( ( ( data_length + index_length ) / 1024 / 1024 ), 2 ) size_in_mb
from     information_schema.tables 
where    table_schema = '$db_name' -- your db name here
order by size_in_mb desc
```

If you find some surprisingly large version tables, you can use the following SQL to quickly debug problems with versioning changes to fields that we shouldn't care about for versioning (e.g. 'last logged in' date):

```sql
select    count(*) as _record_count
        , _version_changed_fields
from      _version_pobj_my_table 
group by  _version_changed_fields
order by  _record_count desc;
```

If you find large numbers of version changes for fields that should not count as a new version record, you can add the `ignoreChangesForVersioning=true` attribute to the property, e.g.

```luceescript
component {
    // ...
	property name="last_logged_in" type="date" dbtype="datetime" ignoreChangesForVersioning=true;
	// ...
}
```

If your tables are _very_ large, you will need to plan your approach to deleting records that you no longer wish to keep (i.e. either old records or records that are recording redundant changes). 

**DO NOT SIMPLY TRUNCATE A VERSION TABLE THAT IS IN USE**. Each record requires at least one corresponding version record as of 10.7.0.

If you find that you have version tables for objects that do not require versioning, you can simply add the `@versioned false` annotation to your Preside Object CFC. Once the application has been deployed and reloaded, you should be able to drop the redundant version table(s). e.g.

```luceescript
// /application/preside-objects/some_log_object.cfc
/**
 * @versioned false
 *
 */
component {
	// ...
}
```


### Task manager

If you have the `preside-ext-taskmanager` extension installed, you will need to **remove it** before upgrading to 10.7.0 and above. 

Firstly, remove its entry in `/application/extensions/extensions.json`. Then remove the `/application/extensions/preside-ext-taskmanager` folder from your application entirely; how you do that will depend on how you have installed the extension. If you have installed as a git submodule:

```
git submodule deinit application/extensions/preside-ext-taskmanager
git rm application/extensions/preside-ext-taskmanager
```

If you have installed as a commandbox dependency using `box.json`, simply remove any references to it from that file.

### Rules engine

The new rules engine system in 10.7.0 allows you to restrict content based on rules about the currently logged in user. In 10.8.0, this feature is moved forward considerably and we recommend not using the feature in 10.7.0 unless you / your client are well prepared to use it.

The feature is turned off by default in 10.7.0 (turned on in 10.8.0) and you can ensure that it is turned off with the following in `Config.cfc`:

```
settings.features.rulesEngine.enabled = false;
```

If you _do_ opt to turn it on, familiarize yourself with the changes it brings in your testing environments and your system users for the changes.