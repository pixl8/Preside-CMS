/**
 * The asset object represents the core data associated with any file uploaded into the Asset manager
 *
 */
component extends="preside.system.base.SystemPresideObject" labelfield="title" displayName="Asset" {

	property name="asset_folder" relationship="many-to-one"                          required=true   uniqueindexes="assetfolder|1" onupdate="cascade-if-no-cycle-check";

	property name="title"             type="string"  dbtype="varchar" maxLength=150     required=true   uniqueindexes="assetfolder|2";
	property name="file_name"         type="string"  dbtype="varchar" maxLength=150     required=false  indexes="filename";
	property name="storage_path"      type="string"  dbtype="varchar" maxLength=255     required=true   uniqueindexes="assetpath";
	property name="asset_url"         type="string"  dbtype="varchar" maxLength=255     required=false  uniqueindexes="asseturl";
	property name="description"       type="string"  dbtype="text"    maxLength=0       required=false;
	property name="author"            type="string"  dbtype="varchar" maxLength=100     required=false;
	property name="size"              type="numeric" dbtype="int"                       required=true;
	property name="asset_type"        type="string"  dbtype="varchar" maxLength=10      required=true;
	property name="raw_text_content"  type="string"  dbtype="longtext";
	property name="width"             type="numeric" dbtype="int"                       required=false;
	property name="height"            type="numeric" dbtype="int"                       required=false;
	property name="focal_point"       type="string"  dbtype="varchar" maxLength=15      required=false;
	property name="crop_hint"         type="string"  dbtype="varchar" maxLength=30      required=false;
	property name="active_version"    relationship="many-to-one" relatedTo="asset_version" required=false ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";

	property name="is_trashed"        type="boolean" dbtype="boolean"                   required=false default=false;
	property name="trashed_path"      type="string"  dbtype="varchar" maxLength=255     required=false;
	property name="original_title"    type="string"  dbtype="varchar" maxLength=200     required=false;


	property name="access_restriction"                   type="string"  dbtype="varchar" maxLength="7" required=false default="inherit" enum="assetAccessRestriction";
	property name="full_login_required"                  type="boolean" dbtype="boolean"               required=false default=false;
	property name="grantaccess_to_all_logged_in_users"   type="boolean" dbtype="boolean"               required=false default=false;

	property name="access_condition" relationship="many-to-one" relatedto="rules_engine_condition" required=false control="conditionPicker" ruleContext="webrequest" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="created_by"       relationship="many-to-one" relatedTo="security_user"          required=false generator="loggedInUserId"  ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="updated_by"       relationship="many-to-one" relatedTo="security_user"          required=false generator="loggedInUserId"  ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
}