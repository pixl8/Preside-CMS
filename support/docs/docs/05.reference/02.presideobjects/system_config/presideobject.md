---
id: "presideobject-system_config"
title: "System config"
---

## Overview


The system config object is used to store system settings (see :doc:`/devguides/systemsettings`).
See :doc:`/devguides/permissioning` for more information on permissioning.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  system_config</td></tr><tr><th>Table name</th><td>  psys_system_config</td></tr><tr><th>Path</th><td>  /preside-objects/admin/configuration/system_config.cfc</td></tr></table></div>

## Properties


```luceescript
property name="site" relationship="many-to-one" relatedTo="site" uniqueindexes="categorysetting|1";

property name="category" type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|2";
property name="setting"  type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|3";
property name="value"    type="string" dbtype="text"                   required="false";
```