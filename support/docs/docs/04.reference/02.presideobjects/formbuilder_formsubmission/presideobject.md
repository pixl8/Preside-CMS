---
id: "presideobject-formbuilder_formsubmission"
title: "Form builder: form"
---

## Overview


The formbuilder_formsubmission object represents a single submission of a form builder form

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  formbuilder_formsubmission</td></tr><tr><th>Table name</th><td>  psys_formbuilder_formsubmission</td></tr><tr><th>Path</th><td>  /preside-objects/formbuilder/formbuilder_formsubmission.cfc</td></tr></table></div>

## Properties


```luceescript
property name="form"         relationship="many-to-one" relatedto="formbuilder_form" required=true;
property name="submitted_by" relationship="many-to-one" relatedTo="website_user"     required=false renderer="websiteUser";

property name="submitted_data" type="string" dbtype="text"                  required=true  renderer="formbuilderSubmission";
property name="form_instance"  type="string" dbtype="varchar" maxlength=200 required=false;
property name="ip_address"     type="string" dbtype="varchar" maxlength=15  required=false;
property name="user_agent"     type="string" dbtype="text"                  required=false;
```