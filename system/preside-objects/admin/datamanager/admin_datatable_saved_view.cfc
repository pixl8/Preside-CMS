/**
 * Named listing views: a snapshot of filters plus column layout
 * for a user (optionally shared) on a given object listing.
 *
 * @versioned           false
 * @datamanagerEnabled  false
 * @feature             admin
 */
component extends="preside.system.base.SystemPresideObject" displayName="Admin datatable saved view" {
	property name="label"         type="string"  dbtype="varchar"  maxlength=100  required=true;
	property name="owner"         relationship="many-to-one" relatedTo="security_user" required=true indexes="owner" ondelete="cascade";
	property name="object_name"   type="string"  dbtype="varchar"  maxlength=100  required=true indexes="objectlisting|1";
	property name="listing_key"   type="string"  dbtype="varchar"  maxlength=100  required=true indexes="objectlisting|2" default="default";
	property name="context_key"   type="string"  dbtype="varchar"  maxlength=100  required=true indexes="objectlisting|3" default="";
	property name="is_shared"         type="boolean" dbtype="boolean"                 required=false default=false indexes="shared";
	property name="sharing_scope"     type="string"  dbtype="varchar"  maxlength=20    required=false enum="listingViewSharingScope" indexes="sharingscope";
	property name="allow_group_edit"  type="boolean" dbtype="boolean"                  required=false default=false;
	property name="user_groups"       relationship="many-to-many" relatedTo="security_group" relatedVia="admin_datatable_saved_view_user_group";
	property name="columns"           type="string"  dbtype="text"                    required=false autofilter=false;
	property name="filter_state"      type="string"  dbtype="text"                    required=false autofilter=false;
	property name="sort_order"        type="string"  dbtype="text"                    required=false autofilter=false;
}
