---
id: "presidesuperclass-$getemailservice"
title: "$getEmailService()"
---


## Overview




```luceescript
public any function $getEmailService()
```

Returns an instance of the [[api-emailservice]]. This service can be used for
sending templated emails. See [[emailtemplating]] for a full guide.


## Example


```luceescript
var emailTemplates = $getEmailService().listTemplates();
```

