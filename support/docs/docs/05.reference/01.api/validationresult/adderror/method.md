---
id: "validationresult-adderror"
title: "addError()"
---


## Overview




```luceescript
public void function addError(
      required string fieldName
    , required string message  
    ,          array  params   
)
```

Adds an error report to the result.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>fieldName</td><td>string</td><td>Yes</td><td>The name of the field to which the message pertains</td></tr><tr><td>message</td><td>string</td><td>Yes</td><td>The error message, can be plain text or an i18n resource key</td></tr><tr><td>params</td><td>array</td><td>No</td><td>If the message is an i18n resource key, params can be passed here to be used as token replacements in the translation</td></tr></tbody></table></div>