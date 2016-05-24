---
id: formcontrol-readonly
title: "Form control: Read only"
---

The `readonly` form control will output any saved data without rendering any form controls. This can be useful for edit forms where you would like to show the content of a field that cannot be edited.

### Arguments

This control does not take any arguments.

### Example

```xml
<field binding="my_protected_object.title"               control="readonly"   />
<field binding="my_protected_object.website_description" control="richeditor" />
```
