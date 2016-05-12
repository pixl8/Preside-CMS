---
id: formcontrol-derivativePicker
title: "Form control: Derivative Picker"
---

The `derivativePicker` control allows users to select from a list of publicly available asset derivatives (see [[assetmanager]]). It is an extension of the [[formcontrol-select|select control]].

### Arguments

The control accepts no custom arguments, though all arguments that can be passed to [[formcontrol-select|select control]] can be used.

### Example

```xml
<field name="derivatives" control="derivativePicker" multiple="true" sortable="true" />
```