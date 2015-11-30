/**
 * An asset storage location represents a location in which assets
 * are stored. Configuration for the location is stored here
 * so that the asset manager system can know how to interact with the
 * given storage provider in order to store and retrieve files in the correct location
 *
 * @labelfield name
 */
component extends="preside.system.base.SystemPresideObject" displayName="Asset storage location" {
	property name="name"            type="string" dbtype="varchar"  maxlength=200 required=true uniqueindexes="name";
	property name="storageProvider" type="string" dbtype="varchar"  maxlength=100 required=true renderer="assetStorageProvider";
	property name="configuration"   type="string" dbtype="longtext";
}