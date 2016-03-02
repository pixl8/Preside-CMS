---
id: "presideobject-formbuilder_formaction"
title: "Form builder: Action"
---

## Overview


The formbuilder_formaction object represents an individual action that is executed when an instance of a form is submitted.
This could be an action to send an email, POST to a webhook, etc.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  formbuilder_formaction</td></tr><tr><th>Table name</th><td>  psys_formbuilder_formaction</td></tr><tr><th>Path</th><td>  /preside-objects/formbuilder/formbuilder_formaction.cfc</td></tr></table></div>

## Properties


```luceescript
property name="form" relationship="many-to-one" relatedto="formbuilder_form" required=true indexes="form,sortorder|1";

property name="sort_order"    type="numeric" dbtype="int"     required=true indexes="sortorder|2";
property name="action_type"   type="string"  dbtype="varchar" required=true maxlength=100;
property name="configuration" type="string"  dbtype="text"    required=false;
```