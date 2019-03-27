/**
 * Object to represent an email blueprint (an email blueprint provides
 * common settings for an email to use).
 *
 * @labelfield name
 */
 component extends="preside.system.base.SystemPresideObject" {
	property name="name"             type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="blueprintname";
	property name="layout"           type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="recipient_type"   type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="service_provider" type="string"  dbtype="varchar" maxlength=200 required=false;

	property name="recipient_filter" relationship="many-to-one" relatedto="rules_engine_condition";
}