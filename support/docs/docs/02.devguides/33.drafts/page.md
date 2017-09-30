---
id: drafts
title: Drafts system
---

As of Preside 10.7.0, the core versioning system also supports draft changes to records. The site tree will automatically have this feature activated whereas data manager objects will need the feature activated should you wish to use it.

To activate drafts in an object managed in the Data manager, you must annotate your object with the `datamanagerAllowDrafts` attribute (it defaults to `false`). For example:

```luceescript
/**
 * @labelfield             name
 * @dataManagerGroup       widget
 * @datamanagerAllowDrafts true
 */
component {
    property name="name"         type="string" dbtype="varchar" required="true";
    property name="job_title"    type="string" dbtype="varchar";
    property name="biography"    type="string" dbtype="text";
    property name="organisation" type="string" dbtype="varchar";

    property name="image" relationship="many-to-one" relatedTo="asset" allowedtypes="image";
}
```