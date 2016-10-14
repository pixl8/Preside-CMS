---
id: "presideobject-link"
title: "Link"
---

## Overview


The link object represents a link to just about anything, be it page in the site tree, an email address or
plain link

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  link</td></tr><tr><th>Table name</th><td>  psys_link</td></tr><tr><th>Path</th><td>  /preside-objects/core/link.cfc</td></tr></table></div>

## Properties


```luceescript
property name="internal_title"    type="string" dbtype="varchar" maxlength="100" required=true  uniqueindexes="linktitle";
property name="type"              type="string" dbtype="varchar" maxlength="20"  required=false default="external"  format="regex:(email|url|sitetreelink|asset)";
property name="title"             type="string" dbtype="varchar" maxlength="200" required=false;
property name="target"            type="string" dbtype="varchar" maxlength="20"  required=false format="regex:_(blank|self|parent|top)";
property name="text"              type="string" dbtype="varchar" maxlength="400" required=false;

property name="external_protocol" type="string"  dbtype="varchar" maxlength="10"  required=false default="http://" format="regex:(https?|ftp|news)\://";
property name="external_address"  type="string"  dbtype="varchar" maxlength="255" required=false;
property name="email_address"     type="string"  dbtype="varchar" maxlength="255" required=false;
property name="email_subject"     type="string"  dbtype="varchar" maxlength="100" required=false;
property name="email_body"        type="string"  dbtype="varchar" maxlength="255" required=false;
property name="email_anti_spam"   type="boolean" dbtype="boolean"                 required=false default=true;

property name="page"  relationship="many-to-one" relatedto="page"  required=false;
property name="asset" relationship="many-to-one" relatedto="asset" required=false ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
property name="image" relationship="many-to-one" relatedto="asset" required=false ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" allowedTypes="image";

```