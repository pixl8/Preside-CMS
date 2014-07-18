/**
 * An asset folder is a hierarchy of named storage locations for assets (see :doc:`/reference/presideobjects/asset`)
 */
component output="false" extends="preside.system.base.SystemPresideObject" displayName="Asset folder" {
	property name="label" uniqueindexes="folderName|2";
	property name="original_label" type="string" dbtype="varchar" maxLength=200 required="false";

	property name="parent_folder" relationship="many-to-one" relatedTo="asset_folder" required="false" uniqueindexes="folderName|1";

	property name="created_by"  relationship="many-to-one" relatedTo="security_user" required="false" generator="loggedInUserId";
	property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required="false" generator="loggedInUserId";
}