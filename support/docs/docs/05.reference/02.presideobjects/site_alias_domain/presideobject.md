---
id: "presideobject-site_alias_domain"
title: "Site alias domain"
---

## Overview


The Site alias domain object represents a single domain that can also be used to serve the site.
Good examples are when you have a separate domain for serving the mobile version of the site,
i.e. www.mysite.com and m.mysite.com.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  site_alias_domain</td></tr><tr><th>Table name</th><td>  psys_site_alias_domain</td></tr><tr><th>Path</th><td>  /preside-objects/core/site_alias_domain.cfc</td></tr></table></div>

## Properties


```luceescript
property name="domain" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="sitealias|2";
property name="site" relationship="many-to-one"                       required=true uniqueindexes="sitealias|1";
```