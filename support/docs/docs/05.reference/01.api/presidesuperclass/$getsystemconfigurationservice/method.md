---
id: "presidesuperclass-$getsystemconfigurationservice"
title: "$getSystemConfigurationService()"
---


## Overview




```luceescript
public any function $getSystemConfigurationService()
```

Returns an instance of the [[api-systemconfigurationservice]]. See [[editablesystemsettings]] for a full guide.


## Example


```luceescript
$getSystemConfigurationService().saveSetting(
          catetory = "my-settings"
        , setting  = "my-setting"
        , value    = arguments.settingValue
);
```

