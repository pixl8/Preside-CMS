/**
 * An asset folder is a hierarchy of named storage locations for assets (see [[presideobject-asset]])
 */
component output="false" extends="preside.system.base.SystemPresideObject" displayName="Asset folder" {
	property name="label" uniqueindexes="folderName|2";
	property name="allowed_filetypes"    type="string"  dbtype="text"                  required=false;
	property name="max_filesize_in_mb"   type="numeric" dbtype="float"                 required=false maxValue=1000000;
	property name="min_width_in_px"      type="numeric" dbtype="float"                 required=false;
	property name="max_width_in_px"      type="numeric" dbtype="float"                 required=false;
	property name="min_height_in_px"     type="numeric" dbtype="float"                 required=false;
	property name="max_height_in_px"     type="numeric" dbtype="float"                 required=false;
	property name="access_restriction"   type="string"  dbtype="varchar" maxLength="7" required=false default="inherit" enum="assetAccessRestriction";
	property name="full_login_required"  type="boolean" dbtype="boolean"               required=false default=false;

	property name="is_system_folder"                      type="boolean" dbtype="boolean"               required=false default=false;
	property name="system_folder_key"                     type="string"  dbtype="varchar" maxLength=200 required=false indexes="systemfolderkey";
	property name="hidden"                                type="boolean" dbtype="boolean"               required=false default=false;
	property name="grantaccess_to_all_logged_in_users"    type="boolean" dbtype="boolean"               required=false default=false;

	property name="is_trashed"           type="boolean" dbtype="boolean"               required=false default=false;
	property name="original_label"       type="string"  dbtype="varchar" maxLength=200 required=false;

	property name="parent_folder"    relationship="many-to-one" relatedTo="asset_folder"           required=false uniqueindexes="folderName|1" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="child_folders"    relationship="one-to-many" relatedTo="asset_folder"           required=false relationshipKey="parent_folder";
	property name="storage_location" relationship="many-to-one" relatedTo="asset_storage_location" required=false;
	property name="access_condition" relationship="many-to-one" relatedto="rules_engine_condition" required=false control="conditionPicker" ruleContext="webrequest";

	property name="created_by"  relationship="many-to-one" relatedTo="security_user" required="false" generator="loggedInUserId" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required="false" generator="loggedInUserId" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
}