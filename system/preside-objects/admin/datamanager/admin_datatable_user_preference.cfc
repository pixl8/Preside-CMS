/**
 * Stores per-user listing column and active-view preferences.
 * `listing_key` defaults to the object name; pass `args.listingPreferenceKey`
 * from `_objectDataTable` when the same object is listed in multiple slots
 * on one page. `context_key` is the resolved listing context (a developer
 * key, or the ajax datasource query string minus cache-busters).
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
	property name="context_key"   type="string" dbtype="varchar" maxlength=100 required=true default="" uniqueindexes="userobjectlisting|4";
	property name="active_view"   type="string" dbtype="varchar" maxlength=40  required=false;
	property name="columns"       type="string" dbtype="text"    required=false;
}
