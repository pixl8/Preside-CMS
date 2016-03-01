---
id: "presidesuperclass-$isfeatureenabled"
title: "$isFeatureEnabled()"
---


## Overview




```luceescript
public any function $isFeatureEnabled()
```

Proxy to the [[featureservice-isfeatureenabled]] method of the [[api-featureservice]].


## Example


```luceescript
if ( $isFeatureEnabled( "websiteUsers" ) ) {
        // ...
}
```

