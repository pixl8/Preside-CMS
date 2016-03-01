---
id: "formbuildervalidationservice-validateformsubmission"
title: "validateFormSubmission()"
---


## Overview




```luceescript
public any function validateFormSubmission(
      required array  formItems     
    , required struct submissionData
)
```

Validates the given submission data against a set of form builder form items.
Returns a preside Validation framework's 'ValidationResult' object.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formItems</td><td>array</td><td>Yes</td><td>Array of form item definitions for the form</td></tr><tr><td>submissionData</td><td>struct</td><td>Yes</td><td>Struct of data that has been submitted for validation</td></tr></tbody></table></div>