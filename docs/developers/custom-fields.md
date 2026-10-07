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

Static values live in a generated table per opted-in object. If the host table is `pobj_my_table`, the value table is `_cfv_pobj_my_table`. Database-defined custom objects are the exception: every `cobj_*` object stores its values in the shared `_cfv_custom_object_record` table. See [Custom objects](custom-objects.md).

- `psys_custom_field.id` is a bigint autoincrement primary key
- Value table: bigint increment primary key
- `record` many-to-one to the host (cascade delete)
- `field` many-to-one to `custom_field` (cascade delete, bigint)
- Typed columns: `field_value`, `shorttext_value`, `date_value`, `boolean_value`, `int_value`, `float_value`

The value tables themselves are not versioned. When the host object is versioned, each host `_version_*` row stores a JSON snapshot in `_version_custom_fields`. Saving the host record snapshots the current values onto that version. Restoring a historical version rehydrates the EAV table from that snapshot.

Enabling custom fields on an object is a schema change (`autoSyncDb=false` sites pick this up in the usual SQL upgrade). Existing rows in the old shared `psys_custom_field_value` table are copied into the per-object tables on db sync; drop `psys_custom_field_value` afterwards.

## Field kinds (v1)

- **Static** — stored in `_cfv_{hostTable}` (EAV, typed columns). Types: text, textarea, integer, float, boolean, date, datetime, lookup, object_ref.
- **Aggregate** — count/sum/min/max/avg over a one-to-many or many-to-many collection on the host object. Optional data filter on the related records (for example, count of London addresses). Read-only. If the object has no suitable collection, this is caught when configuring the aggregation.
- **Related data** — a column, custom field or formula field from a related record reached through one or more many-to-one relationships (for example, logo title, or logo folder label). Read-only. If the object has no many-to-one relationship, this is caught when choosing the related field.
- **Conditional label** — ordered filter/label/colour rules. Each rule requires a condition. Single mode shows the first matching label; multiple mode shows every matching label.

Free-form SQL formulas are out of v1.

## Default admin UI

- Privileged admins manage field definitions from the **Custom fields** data manager (admin menu). Host object listings do not nest that management under the parent object.
- Creating a field is an admin webflow: identity and type; kind-specific config (related object, display, aggregate, or related-data tree); for stored fields, whether they appear on the add form, the edit form, or both, and where on those forms; then listing, filter, export and batch-edit. Lookup options and conditional labels are still added from the field’s view-record tabs after save.
- Fields default to **inactive**. Activate immediately in the last step, or later from the field’s view-record screen (or the listing row action). Inactive fields are hidden from listings, export, filters and record screens.
- Editing a field is type-specific. Related-record stored fields pick an object and can allow multiple related records. Multiple values are stored as a comma-separated list of record ids on that field's value row. Aggregates pick a related collection, method, optional numeric field and optional related-record filter (the same shape as data-viz metrics). Related data fields use a tree of many-to-one relationships; expand a hop to load fields (including custom fields and formula fields) on that related record.
- Lookup options and conditional labels are managed from dedicated tabs on the field’s view-record screen (listing table with add, edit and delete). Conditional labels are ordered with the tab’s **Sort records** button (core data manager sorting, scoped to that field).
- Conditional-label columns cannot be sorted. Their quick filter accepts one or more configured labels; selections are ORed. In single mode, filtering for a label also excludes records matching any earlier label rule so results match what is displayed.
- Sort fields for an object with the listing **Sort** button when the listing is scoped to a single target object (core data manager sorting). A custom object's **Fields** tab has the same **Sort fields** button when the object has more than one field. Sorting is limited to that object's fields and returns to the tab.
- View record shows a **Custom fields** group.
- Static fields appear on the standard add and edit forms. By default they sit on a **Custom fields** tab. A field can be limited to the add form, the edit form, or both, or placed on an existing tab and fieldset (or a new tab and fieldset created for custom fields). A field on those forms can be marked **Required**; an empty value then fails form validation. Values are edited on those forms.
- Aggregates, related data and conditional labels are read-only everywhere and are not added to add or edit forms.
- Each field can be marked **Show in datamanager listings** (on by default). When off, it is omitted from the listing column picker.
- Each field can be marked **Allow in listing filters** (on by default, always off for conditional labels). When off, it is omitted from listing filters and rules-engine auto expressions. Lookup fields use a "matches option(s)" expression whose choices are that field's lookup values.
- Each field can be marked **Include in data export** (on by default). When off, it is omitted from export field pickers and default export columns.
- Stored fields can be marked **Batch editable** (on by default). Flagged static fields appear in the listing batch-edit menu and persist through the per-object value table.
- Deleting a field opens a confirmation screen. The button is labelled **Delete...**. The admin must type the field name. Stored fields report how many records have a value. Confirming runs the standard data manager delete, including the delete permission and the audit log.

Permissions `customfields.add`, `customfields.edit`, `customfields.delete` are required to define and manage fields. Editing values uses the host object’s existing `edit` permission.
