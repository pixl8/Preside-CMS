/**
 * Assigns a named listing view as the Default for a person,
 * a permission group, or everyone on a given object listing.
 *
 * @nolabel             true
 * @versioned           false
 * @datamanagerEnabled  false
 * @feature             admin
 */
component extends="preside.system.base.SystemPresideObject" displayName="Admin datatable listing default" {
	property name="object_name"     type="string" dbtype="varchar" maxlength=100 required=true indexes="listingdefault|1";
	property name="listing_key"     type="string" dbtype="varchar" maxlength=100 required=true indexes="listingdefault|2" default="default";
	property name="context_key"     type="string" dbtype="varchar" maxlength=100 required=true indexes="listingdefault|3" default="";
	property name="scope"           type="string" dbtype="varchar" maxlength=20  required=true enum="listingViewDefaultScope" indexes="listingdefault|4";
	property name="security_user"   relationship="many-to-one" relatedTo="security_user"               required=false indexes="listingdefaultuser"  ondelete="cascade";
	property name="security_group"  relationship="many-to-one" relatedTo="security_group"              required=false indexes="listingdefaultgroup" ondelete="cascade";
	property name="saved_view"      relationship="many-to-one" relatedTo="admin_datatable_saved_view"  required=true  indexes="listingdefaultview" ondelete="cascade";
}
