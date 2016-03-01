---
id: "formbuilderactionsservice-triggersubmissionactions"
title: "triggerSubmissionActions()"
---


## Overview




```luceescript
public void function triggerSubmissionActions(
      required string formId        
    , required struct submissionData
)
```

Fires of submit handlers for each registered action
in the form

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>ID of the form who's actions we are to trigger</td></tr><tr><td>submissionData</td><td>struct</td><td>Yes</td><td>The form submission itself</td></tr></tbody></table></div>