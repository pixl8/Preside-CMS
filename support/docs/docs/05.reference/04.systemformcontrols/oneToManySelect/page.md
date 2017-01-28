---
id: formcontrol-oneToManySelect
title: "Form control: One-to-many select"
---

The `oneToManySelect` control is a variation of the [[formcontrol-objectpicker|Object picker]] that allows you to select all the related records that should "belong" to the current record (the record that you are in the process of creating / editing).

For example, you may have a user group relationship where a user can belong to zero or _one_ group. In the `group` object, you could define a `users` property with a `one-to-many` relationship and have it use the `oneToManySelect` form control. When creating or editing a group, you can then define directly which users belong to the group.

### Arguments

_This control has no custom arguments._

### Example

```luceescript
// /preside-objects/user.cfc
...
property name="group" relationship="many-to-one" relatedTo="group";
...
```

```luceescript
// /preside-objects/group.cfc
...
property name="users" relationship="one-to-many" relatedTo="user" relationshipKey="group";
...
```

```xml
<!-- /forms/preside-objects/group/admin.edit.xml -->
<!-- /forms/preside-objects/group/admin.add.xml -->
<!-- ... -->
<field binding="group.users" control="oneToManySelect" />
```
