---
id: "presideobject-workflow_state"
title: "Workflow: State"
---

## Overview


The workflow_state object saves the state and status of a single workflow item

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  workflow_state</td></tr><tr><th>Table name</th><td>  psys_workflow_state</td></tr><tr><th>Path</th><td>  /preside-objects/workflow/workflow_state.cfc</td></tr></table></div>

## Properties


```luceescript
property name="workflow"  type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|1";
property name="reference" type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|2";
property name="owner"     type="string" dbtype="varchar" maxlength=50 required=true uniqueindexes="workflowstate|3";
property name="state"     type="string" dbtype="text";
property name="status"    type="string" dbtype="varchar" maxlength=50 required=true;
property name="expires"   type="date"   dbtype="datetime" required=false;

```