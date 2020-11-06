/**
 * The rules engine condition object represents a globally saved condition
 * that can be used to build dynamic rules throughout the system. See
 * [[rules-engine]] for a detailed guide
 *
 * @labelfield condition_name
 * @datamanagerEnabled true
 * @dataManagerGridFields kind,condition_name,applies_to,filter_sharing_scope,owner,datemodified
 * @datamanagerDisallowedOperations read
 */
component extends="preside.system.base.SystemPresideObject" displayName="Rules engine: condition" {
	property name="condition_name"   type="string"  dbtype="varchar"  required=true  maxlength=200  uniqueindexes="contextname|2,filterobjectname|2" batcheditable=false;
	property name="context"          type="string"  dbtype="varchar"  required=false maxlength=100  uniqueindexes="contextname|1"      renderer="rulesEngineContextName" indexes="context" batcheditable=false;
	property name="filter_object"    type="string"  dbtype="varchar"  required=false maxlength=100  uniqueindexes="filterobjectname|1" renderer="objectName" batcheditable=false;
	property name="expressions"      type="string"  dbtype="longtext" required=true batcheditable=false;

	property name="filter_sharing_scope" type="string"  dbtype="varchar"  required=false enum="rulesfilterScopeAll" indexes="sharingscope" renderer="rulesEngineShareScope" batcheditable=false;
	property name="is_favourite"         type="boolean" dbtype="boolean"  required=false default=false;
	property name="allow_group_edit"     type="boolean" dbtype="boolean"  required=false default=false generator="rulesfilter.allowGroupEdit" generate="always" batcheditable=false;

	property name="owner"         relatedTo="security_user"              relationship="many-to-one" generator="rulesfilter.owner" generate="always" renderer="rulesEngineOwner" batcheditable=false;
	property name="user_groups"   relatedTo="security_group"             relationship="many-to-many" relatedVia="rules_filter_user_group" batcheditable=false;
	property name="filter_folder" relatedTo="rules_engine_filter_folder" relationship="many-to-one";

	// helper formula fields for displays
	property name="kind" type="string" formula="case when ${prefix}filter_object is null then 'condition' else 'filter' end" autofilter="false" renderer="enumlabel" enum="rulesEngineConditionType" control="none";
	property name="applies_to" type="string" formula="coalesce( ${prefix}filter_object, ${prefix}context )" renderer="rulesEngineAppliesTo"  autofilter="false" control="none";
}