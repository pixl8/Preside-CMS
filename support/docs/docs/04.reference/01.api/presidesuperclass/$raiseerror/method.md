---
id: "presidesuperclass-$raiseerror"
title: "$raiseError()"
---


## Overview




```luceescript
public any function $raiseError()
```

Proxy to the [[errorlogservice-raiseerror]] method of the [[api-errorlogservice]].
Raises an error with the system.


## Example


```luceescript
try {
        result = input / 0;
} catch( any e ) {
        $raiseError( e );
}
```

