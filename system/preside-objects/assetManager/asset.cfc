component extends="preside.system.base.SystemPresideObject" output=false {

	property name="asset_folder" relationship="many-to-one"                          required=true   uniqueindexes="assetfolder|1";

	property name="label"                                             maxLength=150     required=true   uniqueindexes="assetfolder|2";
	property name="original_label"    type="string"  dbtype="varchar" maxLength=200     required=false;
	property name="storage_path"      type="string"  dbtype="varchar" maxLength=255     required=true   uniqueindexes="assetpath";
	property name="trashed_path"      type="string"  dbtype="varchar" maxLength=255     required=false;
	property name="description"       type="string"  dbtype="text"    maxLength=0       required=false;
	property name="author"            type="string"  dbtype="varchar" maxLength=100     required=false;
	property name="size"              type="numeric" dbtype="int"                       required=true;
	property name="asset_type"        type="string" dbtype="varchar" maxLength=10       required=true;

	property name="created_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId";
	property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId";
}