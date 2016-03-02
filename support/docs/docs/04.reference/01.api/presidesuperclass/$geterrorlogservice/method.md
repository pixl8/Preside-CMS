---
id: "presidesuperclass-$geterrorlogservice"
title: "$getErrorLogService()"
---


## Overview




```luceescript
public any function $getErrorLogService()
```

Returns an instance of the [[api-errorlogservice]]. This service
can be used to raise and query system errors.


## Example


```luceescript
$getErrorLogService().deleteAllErrors();
```

