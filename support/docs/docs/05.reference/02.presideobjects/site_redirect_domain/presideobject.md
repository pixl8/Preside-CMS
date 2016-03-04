---
id: "presideobject-site_redirect_domain"
title: "Site redirect domain"
---

## Overview


The Site redirect domain object represents a single domain that will permanently redirect to the
default domain for a site.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  site_redirect_domain</td></tr><tr><th>Table name</th><td>  psys_site_redirect_domain</td></tr><tr><th>Path</th><td>  /preside-objects/core/site_redirect_domain.cfc</td></tr></table></div>

## Properties


```luceescript
property name="domain" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="sitedomain|2";
property name="site" relationship="many-to-one"                       required=true uniqueindexes="sitedomain|1";
```