/**
 * The asset derivative object represents a derived version of an :doc:`/reference/presideobjects/asset`, storing the file path and named derivative used to transform the initial asset.
 */
component extends="preside.system.base.SystemPresideObject" output=false displayName="Asset derivative" feature="assetManager" {

	property name="asset"         relationship="many-to-one" required=true  uniqueindexes="derivative|1";
	property name="asset_version" relationship="many-to-one" required=false uniqueindexes="derivative|2";

	property name="label" maxLength=200 required=true uniqueindexes="derivative|3";

	property name="storage_path" type="string" dbtype="varchar" maxLength=255 required=true   uniqueindexes="assetpath";
	property name="trashed_path" type="string" dbtype="varchar" maxLength=255 required=false;
	property name="asset_type"   type="string" dbtype="varchar" maxLength=10  required=true;
}