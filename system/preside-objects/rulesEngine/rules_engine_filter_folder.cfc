/**
 * The rules engine filter folder object stores user generated
 * folders that store filters for an object
 *
 * @versioned          false
 * @datamanagerEnabled true
 */
component extends="preside.system.base.SystemPresideObject" displayName="Rules engine: condition" {
	property name="label"                                       required=true maxlength=50   uniqueindexes="foldername|2";
	property name="object_name" type="string"  dbtype="varchar" required=true maxlength=100  uniqueindexes="foldername|1";

	property name="filters" relationship="one-to-many" relatedto="rules_engine_condition" relationshipKey="filter_folder";
}