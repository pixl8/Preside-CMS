/**
 * The asset version object represents the file information for a specific version of a file for a given asset
 * The active asset version's file details are duplicated in the asset object to reduce API and querying complexity
 * \n
 * i.e. to get the file details of the active version of a given asset, one simply has to query the asset itself. This has
 * also been done to make upgrades easier as this asset version feature has been added later.
 *
 * @feature assetManager
 */
component extends="preside.system.base.SystemPresideObject" labelfield="title" displayName="Asset version" {

	property name="asset"             relationship="many-to-one" relatedTo="asset"      required=true  uniqueindexes="assetversion|1" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="version_number"    type="numeric" dbtype="int"                       required=true  uniqueindexes="assetversion|2";

	property name="storage_path"      type="string"  dbtype="varchar" maxLength=255     required=true  uniqueindexes="assetversionpath";
	property name="asset_url"         type="string"  dbtype="varchar" maxLength=1024    required=false;
	property name="size"              type="numeric" dbtype="int"                       required=true;
	property name="asset_type"        type="string"  dbtype="varchar" maxLength=10      required=true;
	property name="raw_text_content"  type="string"  dbtype="longtext";
	property name="width"             type="numeric" dbtype="int"                       required=false;
	property name="height"            type="numeric" dbtype="int"                       required=false;
	property name="focal_point"       type="string"  dbtype="varchar" maxLength=15      required=false;
	property name="crop_hint"         type="string"  dbtype="varchar" maxLength=30      required=false;
	property name="resize_no_crop"    type="boolean" dbtype="boolean" default=false;

	property name="is_trashed"   type="boolean" dbtype="boolean"               required=false default=false;
	property name="trashed_path" type="string"  dbtype="varchar" maxLength=255 required=false;

	property name="created_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="LoggedInUser.loggedInUserId" generate="insert" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="LoggedInUser.loggedInUserId" generate="always" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";

}