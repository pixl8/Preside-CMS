/**
 * The asset object represents the core data associated with any file uploaded into the Asset manager
 *
 */
component extends="preside.system.base.SystemPresideObject" labelfield="title" output=false displayName="Asset" {

	property name="asset_folder" relationship="many-to-one"                          required=true   uniqueindexes="assetfolder|1";

	property name="title"             type="string"  dbtype="varchar" maxLength=150     required=true   uniqueindexes="assetfolder|2";
	property name="storage_path"      type="string"  dbtype="varchar" maxLength=255     required=true   uniqueindexes="assetpath";
	property name="description"       type="string"  dbtype="text"    maxLength=0       required=false;
	property name="author"            type="string"  dbtype="varchar" maxLength=100     required=false;
	property name="size"              type="numeric" dbtype="int"                       required=true;
	property name="asset_type"        type="string"  dbtype="varchar" maxLength=10      required=true;
	property name="raw_text_content"  type="string"  dbtype="longtext";
	property name="width"             type="numeric" dbtype="int"                       required=false;
	property name="height"            type="numeric" dbtype="int"                       required=false;
	property name="active_version"    relationship="many-to-one" relatedTo="asset_version" required=false ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";

	property name="is_trashed"        type="boolean" dbtype="boolean"                   required=false default=false;
	property name="trashed_path"      type="string"  dbtype="varchar" maxLength=255     required=false;
	property name="original_title"    type="string"  dbtype="varchar" maxLength=200     required=false;


	property name="access_restriction"  type="string"  dbtype="varchar" maxLength="7" required=false default="inherit" format="regex:(inherit|none|full)"  control="select" values="inherit,none,full" labels="preside-objects.asset:access_restriction.option.inherit,preside-objects.asset:access_restriction.option.none,preside-objects.asset:access_restriction.option.full";
	property name="full_login_required" type="boolean" dbtype="boolean"               required=false default=false;

	property name="created_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
}