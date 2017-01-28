/**
 * The rules engine condition object represents a globally saved condition
 * that can be used to build dynamic rules throughout the system. See
 * [[rules-engine]] for a detailed guide
 *
 * @labelfield condition_name
 */
component extends="preside.system.base.SystemPresideObject" displayName="Rules engine: condition" {
	property name="condition_name" type="string" dbtype="varchar" maxlength=200 required=true uniqueindexes="name";
	property name="context"        type="string" dbtype="varchar" maxlength=100 required=true indexes="context";
	property name="expressions"    type="string" dbtype="text"                  required=true;
}