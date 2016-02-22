---
id: "storageprovider-validate"
title: "validate()"
---


## Overview




```luceescript
public any function validate(
      required struct configuration   
    , required any    validationResult
)
```

A method to validate proposed configuration for the provider. The validate
method should ensure that the configuration works (e.g. able to connect
to CDN with provided credentials) and flag any errors using the passed
[[api-validationresult]] object.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>configuration</td><td>struct</td><td>Yes</td><td>a structure containing configuration keys and values</td></tr><tr><td>validationResult</td><td>any</td><td>Yes</td><td>A [[api-validationresult]] object with which problems can be reported.</td></tr></tbody></table></div>