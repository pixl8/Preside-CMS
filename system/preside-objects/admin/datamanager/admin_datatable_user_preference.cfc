/**
 * Stores per-user, per-object listing column preferences. `listing_key`
 * defaults to the object name; pass `args.listingPreferenceKey` from
 * `_objectDataTable` when the same object is listed in multiple contexts.
 *
 * @nolabel             true
 * @versioned           false
 * @datamanagerEnabled  false
 * @feature             admin
 */
component extends="preside.system.base.SystemPresideObject" displayName="Admin datatable user preference" {
	property name="security_user" relationship="many-to-one" relatedTo="security_user" required=true uniqueindexes="userobjectlisting|1" ondelete="cascade";
	property name="object_name"   type="string" dbtype="varchar" maxlength=100 required=true uniqueindexes="userobjectlisting|2";
	property name="listing_key"   type="string" dbtype="varchar" maxlength=100 required=true default="default" uniqueindexes="userobjectlisting|3";
	property name="columns"       type="string" dbtype="text"    required=false;
}
