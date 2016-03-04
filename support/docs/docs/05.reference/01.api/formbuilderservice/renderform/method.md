---
id: "formbuilderservice-renderform"
title: "renderForm()"
---


## Overview




```luceescript
public string function renderForm(
      required string formId          
    ,          string layout           = "default"
    ,          struct configuration   
    ,          any    validationResult = ""
)
```

Renders the given form within a passed layout
and using any passed custom configuration data.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>The ID of the form to render</td></tr><tr><td>layout</td><td>string</td><td>No (default="default")</td><td>The form layout to use</td></tr><tr><td>configuration</td><td>struct</td><td>No</td><td>Struct containing any custom configuration that may be used by the viewlets used to render the form</td></tr><tr><td>validationResult</td><td>any</td><td>No (default="")</td><td></td></tr></tbody></table></div>