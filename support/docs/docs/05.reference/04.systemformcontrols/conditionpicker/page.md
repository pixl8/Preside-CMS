---
id: formcontrol-conditionpicker
title: "Form control: Condition picker"
---

The `conditionPicker` control is an [[formcontrol-objectPicker| object picker]] with custom options and interface specific to rules engine conditions.

### Arguments

You can use any arguments that can be used with the [[object picker]]. In addition, the control accepts a single option, `ruleContext` indicating the [[rulesenginecontexts|rules engine context]] with which to filter the available conditions (see [[rulesengine]] for more details on condition contexts). The default `ruleContext` is `webrequest`.


### Example

```xml
<field name="access_condition" control="conditionPicker" ruleContext="user" />
```