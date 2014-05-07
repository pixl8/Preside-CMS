component extends="preside.system.base.SystemPresideObject" output=false {

	property name="asset"      relationship="many-to-one" required=true uniqueindexes="derivative|1";

	property name="label" maxLength=50 required=true uniqueindexes="derivative|2"; // unique derivative label per asset

	property name="storage_path" type="string" dbtype="varchar" maxLength=255 required=true   uniqueindexes="assetpath";
	property name="trashed_path" type="string" dbtype="varchar" maxLength=255 required=false;
	property name="asset_type"   type="string" dbtype="varchar" maxLength=10  required=true;
}