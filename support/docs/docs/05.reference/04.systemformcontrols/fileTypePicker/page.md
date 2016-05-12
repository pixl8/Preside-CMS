---
id: formcontrol-fileTypePicker
title: "Form control: File Type Picker"
---

The `fileTypePicker` control allows users to select from a list of file types that have been configured for the asset manager (see [[assetmanager]]). It is an extension of the [[formcontrol-select|select control]].

### Arguments

The control accepts no custom arguments, though all arguments that can be passed to [[formcontrol-select|select control]] can be used.

### Example

```xml
<field name="filetypes" control="fileTypePicker" multiple="true" sortable="true" />
```

![Screenshot of filetype picker](images/screenshots/fileTypePicker.png)