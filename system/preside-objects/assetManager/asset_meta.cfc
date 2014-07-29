/**
 * The asset meta object represents a single item of extracted meta data from an asset file
 *
 */
component extends="preside.system.base.SystemPresideObject" labelfield="key" output=false displayName="Asset meta data" versioned=false {
 	property name="asset" relationship="many-to-one"                   required=true   uniqueindexes="assetmeta|1";
	property name="key"   type="string" dbtype="varchar" maxLength=150 required=true   uniqueindexes="assetmeta|2";
	property name="value" type="string" dbtype="text"                  required=false;
}