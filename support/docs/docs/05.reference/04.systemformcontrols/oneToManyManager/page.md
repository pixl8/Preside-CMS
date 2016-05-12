---
id: formcontrol-oneToManyManager
title: "Form control: One-to-many manager"
---

The `oneToManyManager` form control is actually an link to an iframe modal that helps you manage related data to a record. This control is automatically used when you declare a `one-to-many` property in a preside object and include that property in a form.

### Arguments

This control is currently only used automatically for form fields that bind to `one-to-many` preside object properties. It does not accept any custom arguments.

### Example

```luceescript
// /preside-objects/consultation.cfc
...
property name="sections" relationship="one-to-many" relatedTo="consultation_section" relationshipKey="consultation";
...
```

```xml
<!-- /forms/preside-objects/consultation/admin.edit.xml -->
<!-- ... -->
<field binding="consultation.sections" />
```

![Screenshot of one to many manager link](images/screenshots/oneToManyManagerLink.png)
![Screenshot of one to many manager dialog](images/screenshots/oneToManyManagerDialog.png)