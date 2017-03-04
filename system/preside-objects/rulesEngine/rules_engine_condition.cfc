/**
 * The rules engine condition object represents a globally saved condition
 * that can be used to build dynamic rules throughout the system. See
 * [[rules-engine]] for a detailed guide
 *
 * @labelfield condition_name
 */
component extends="preside.system.base.SystemPresideObject" displayName="Rules engine: condition" {
	property name="condition_name" type="string"  dbtype="varchar"  required=true  maxlength=200  uniqueindexes="contextname|2,filterobjectname|2";
	property name="context"        type="string"  dbtype="varchar"  required=false maxlength=100  uniqueindexes="contextname|1"      renderer="rulesEngineContextName" indexes="context";
	property name="filter_object"  type="string"  dbtype="varchar"  required=false maxlength=100  uniqueindexes="filterobjectname|1" renderer="objectName";
	property name="expressions"    type="string"  dbtype="longtext" required=true;
	property name="is_favourite"   type="boolean" dbtype="boolean"  required=false default=false;
}