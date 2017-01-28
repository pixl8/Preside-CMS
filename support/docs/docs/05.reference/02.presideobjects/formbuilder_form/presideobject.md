---
id: "presideobject-formbuilder_form"
title: "Form builder: form"
---

## Overview


The formbuilder_form object represents a single form within the form builder system

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  formbuilder_form</td></tr><tr><th>Table name</th><td>  psys_formbuilder_form</td></tr><tr><th>Path</th><td>  /preside-objects/formbuilder/formbuilder_form.cfc</td></tr></table></div>

## Properties


```luceescript
property name="name"                   type="string"  dbtype="varchar" maxlength=255 required=true uniqueindexes="formname";
property name="button_label"           type="string"  dbtype="varchar" maxlength=255 required=true;
property name="form_submitted_message" type="string"  dbtype="text"                  required=true;
property name="use_captcha"            type="boolean" dbtype="boolean"               required=false default=true;
property name="description"            type="string"  dbtype="text"                  required=false;
property name="locked"                 type="boolean" dbtype="boolean"               required=false default=false;
property name="active"                 type="boolean" dbtype="boolean"               required=false default=false;
property name="active_from"            type="date"    dbtype="datetime"              required=false;
property name="active_to"              type="date"    dbtype="datetime"              required=false;

property name="items" relationship="one-to-many" relatedto="formbuilder_formitem" relationshipKey="form";
```