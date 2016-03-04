---
id: "formbuilderservice-saveformsubmission"
title: "saveFormSubmission()"
---


## Overview




```luceescript
public any function saveFormSubmission(
      required string formId     
    , required struct requestData
    ,          string instanceId  = ""
    ,          string ipAddress  
    ,          string userAgent  
)
```

Saves a form submission. Returns a validation result. If validation
failed, no data will be saved in the database.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>The ID of the form builder form</td></tr><tr><td>requestData</td><td>struct</td><td>Yes</td><td>A struct containing request data</td></tr><tr><td>instanceId</td><td>string</td><td>No (default="")</td><td>Free text string representing the instance of a form builder form in the website (see form builder form widget)</td></tr><tr><td>ipAddress</td><td>string</td><td>No</td><td>IP address of the visitor making the submission</td></tr><tr><td>userAgent</td><td>string</td><td>No</td><td>User agent of the visitor making the submission</td></tr></tbody></table></div>