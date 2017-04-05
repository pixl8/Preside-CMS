---
id: formcontrol-filterpicker
title: "Form control: Filter picker"
---

The `filterPicker` control is an [[formcontrol-objectPicker| object picker]] with custom options and interface specific to rules engine filters.

### Arguments

You can use any arguments that can be used with the [[object picker]]. In addition, the control expects a single **required** option, `filterObject` indicating the object that selected / added filters should apply to.


### Example

```xml
<field name="optional_filters" control="filterPicker" filterObject="news" multiple="true" sortable="true"  />
```