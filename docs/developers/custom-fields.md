# Custom fields

Privileged admins can attach extra fields to opted-in Preside objects. Fields appear as virtual formula properties, so listing columns, view-record groups, export, and rules-engine auto expressions all reuse existing Preside machinery.

Frontend helpers such as `renderCustomField()` are **not** in v1.

## Enablement

The `customFields` feature is on by default. Objects must still opt in:

```cfc
/**
 * @customFieldsEnabled true
 */
component { ... }
```

Every custom field on an object applies to every record of that object.

## Storage

Static values live in a generated table per opted-in object. If the host table is `pobj_my_table`, the value table is `_cfv_pobj_my_table`.

- `psys_custom_field.id` is a bigint autoincrement primary key
- Value table: bigint increment primary key
- `record` many-to-one to the host (cascade delete)
- `field` many-to-one to `custom_field` (cascade delete, bigint)
- Typed columns: `field_value`, `shorttext_value`, `date_value`, `boolean_value`, `int_value`, `float_value`

The value tables themselves are not versioned. When the host object is versioned, each host `_version_*` row stores a JSON snapshot in `_version_custom_fields`. Restoring a historical version rehydrates the EAV table from that snapshot. Dedicated **Edit custom fields** forces a new host version.

Enabling custom fields on an object is a schema change (`autoSyncDb=false` sites pick this up in the usual SQL upgrade). Existing rows in the old shared `psys_custom_field_value` table are copied into the per-object tables on db sync; drop `psys_custom_field_value` afterwards.

## Field kinds (v1)

- **Static** — stored in `_cfv_{hostTable}` (EAV, typed columns). Types: text, textarea, integer, float, boolean, date, datetime, lookup, object_ref.
- **Aggregate** — count/sum/min/max/avg over a many-to-many or one-to-many property. Read-only.
- **Conditional label** — ordered filter/label/style rules. Display-only (`autofilter=false`).

Free-form SQL formulas are out of v1.

## Default admin UI

- Listing screens of opted-in objects get **Add custom field** / **Custom fields**.
- Creating a field is a short first step: label, key (autoslug), field type, data type, and listing/export options. The field is saved **inactive**.
- Editing a field is type-specific. Related-record fields pick an object; aggregates pick a collection and function.
- Lookup options and conditional labels are managed from dedicated tabs on the field’s view-record screen (listing table with add, edit and delete).
- Activate the field from the edit screen when configuration is complete.
- View record shows a **Custom fields** group.
- **Edit custom fields** is a dedicated action for static fields that are not placed inline.
- Aggregates and conditional labels are read-only everywhere.
- Each field can be marked **Include in data export** (on by default). When off, it is omitted from export field pickers and default export columns.
- Stored fields can be marked **Batch editable** (on by default). Flagged static fields appear in the listing batch-edit menu and persist through the per-object value table.

Permission `customfields.manage` is required to define fields. Editing values uses the host object’s existing `edit` permission.

## Slot / placement API

```cfc
settings.customFields.objects.elf_test_object = {
	  defaultSlot = "custom"
	, slots       = {
		custom = {
			viewGroup = "customFields"
			// no forms → dedicated Edit custom fields screen
		}
		// example of developer placement:
		// main = {
		//     viewGroup = "default",
		//     forms = {
		//         "preside-objects.elf_test_object.admin.edit" = { fieldset="default", after="status" },
		//         "preside-objects.elf_test_object.admin.add"  = { fieldset="default", after="status" }
		//     }
		// }
	  }
};
```

Fields assigned to an inline form slot are omitted from the dedicated edit screen. `preRenderForm` merges static fields into those forms.
