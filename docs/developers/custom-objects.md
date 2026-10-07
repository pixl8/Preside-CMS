# Custom objects

Privileged admins can define record stores in the database. Each definition becomes a data manager object named `cobj_{key}` without adding a table of its own.

## Storage

`psys_custom_object` holds the definition: label, key, category, icon and whether records have a label.

`psys_custom_object_record` holds every record of every custom object. `datecreated` and `datemodified` are always present. The label column is always in the table; a definition can hide it. When a definition includes the label, add and edit forms require it. The `custom_object` foreign key says which definition a row belongs to.

Custom field values for every custom object share one table, `_cfv_custom_object_record`, created with the normal startup schema sync. Record ids are unique across that shared records table, so values stay separated by record and field. Creating a definition or a field does not run DDL, and deleting one does not drop a table.

Custom objects are not versioned.

## Data manager

An active definition appears on the data manager home. The category is free text, with suggestions. If it matches an existing group title, ignoring case, the object joins that group. Otherwise it appears under a new group whose title is the category text.

Record access uses the standard data manager permissions. With no context permissions saved, a role that has `datamanager.read`, `add`, `edit` or `delete` can perform that operation on every custom object. Manage permissions on an object's listing saves grants and denies for context `datamanager` and context key `cobj_{key}`, and those override the role for that object only.

## Runtime updates

Startup registers the virtual objects and the shared value table. Later changes register, replace or unregister that one object, refresh its labels and its custom-field forms, and clear its caches. They do not reload preside objects, rebuild the schema or reload the forms service.
