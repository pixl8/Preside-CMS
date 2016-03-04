---
id: "presideobject-formbuilder_formitem"
title: "Form builder: Item"
---

## Overview


The formbuilder_formitem object represents an individual item within a form builder form.
This could be a form control, some free text, etc.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  formbuilder_formitem</td></tr><tr><th>Table name</th><td>  psys_formbuilder_formitem</td></tr><tr><th>Path</th><td>  /preside-objects/formbuilder/formbuilder_formitem.cfc</td></tr></table></div>

## Properties


```luceescript
property name="form" relationship="many-to-one" relatedto="formbuilder_form" required=true indexes="form,sortorder|1";

property name="sort_order"    type="numeric" dbtype="int"     required=true indexes="sortorder|2";
property name="item_type"     type="string"  dbtype="varchar" required=true maxlength=100;
property name="configuration" type="string"  dbtype="text"    required=false;
```