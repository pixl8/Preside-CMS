---
id: "presidesuperclass-$getpresidesetting"
title: "$getPresideSetting()"
---


## Overview




```luceescript
public any function $getPresideSetting()
```

Proxy to the [[systemconfigurationservice-getsetting]] method of [[api-systemconfigurationservice]]. See [[editablesystemsettings]] for a full guide.


## Example


```luceescript
var mailServer = $getPresideSetting( category="email", setting="server" );
```

