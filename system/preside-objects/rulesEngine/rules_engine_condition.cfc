/**
 * The rules engine condition object represents a globally saved condition
 * that can be used to build dynamic rules throughout the system. See
 * [[rules-engine]] for a detailed guide
 *
 * @labelfield                      condition_name
 * @datamanagerEnabled              true
 * @dataManagerGridFields           kind,is_locked,condition_name,applies_to,filter_sharing_scope,owner,datemodified
 * @datamanagerDisallowedOperations read,viewversions,batchdelete,batchedit
 * @datamanagerTreeView             true
 * @datamanagerTreeParentProperty   parent_segmentation_filter
 * @feature                         rulesEngine
 */
component extends="preside.system.base.SystemPresideObject" displayName="Rules engine: condition" {
	property name="condition_name"   type="string"  dbtype="varchar"  required=true  maxlength=200  uniqueindexes="contextname|2,filterobjectname|2";
	property name="context"          type="string"  dbtype="varchar"  required=false maxlength=100  uniqueindexes="contextname|1"      renderer="rulesEngineContextName" indexes="context";
	property name="filter_object"    type="string"  dbtype="varchar"  required=false maxlength=100  uniqueindexes="filterobjectname|1" renderer="objectName";
	property name="expressions"      type="string"  dbtype="longtext" required=true;

	property name="filter_sharing_scope" type="string"  dbtype="varchar"  required=false enum="rulesfilterScopeAll" indexes="sharingscope" renderer="rulesEngineShareScope";
	property name="is_favourite"         type="boolean" dbtype="boolean"  required=false default=false;
	property name="allow_group_edit"     type="boolean" dbtype="boolean"  required=false default=false generator="rulesfilter.allowGroupEdit" generate="always";

	property name="owner"         relatedTo="security_user"              relationship="many-to-one" generator="rulesfilter.owner" generate="always" renderer="rulesEngineOwner" ondelete="set-null-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
	property name="user_groups"   relatedTo="security_group"             relationship="many-to-many" relatedVia="rules_filter_user_group";
	property name="filter_folder" relatedTo="rules_engine_filter_folder" relationship="many-to-one";

	property name="is_locked"     type="boolean" dbtype="boolean"  required=false default=false indexes="locked" renderer="conditionLock";
	property name="locked_reason" type="string"  dbtype="text"     required=false renderer="plaintext";

	// properties for "segmentation filters"
	property name="is_segmentation_filter"         type="boolean" dbtype="boolean" default=false batchEditable=false;
	property name="segmentation_frequency_measure" type="numeric" dbtype="int" batchEditable=false minValue=1;
	property name="segmentation_frequency_unit"    type="string"  dbtype="varchar" maxlength=10 batchEditable=false enum="segmentationFilterTimeUnit";
	property name="parent_segmentation_filter" relationship="many-to-one" relatedto="rules_engine_condition" batchEditable=false uniqueindexes="filterobjectname|3" ondelete="cascade-if-no-cycle-check";
	property name="segmentation_last_calculation" type="date"    dbtype="datetime" batcheditable=false ignoreChangesForVersioning=true renderer="lastSegmentationRuleCalculation";
	property name="segmentation_next_calculation" type="date"    dbtype="datetime" batcheditable=false ignoreChangesForVersioning=true;
	property name="segmentation_last_count"       type="numeric" dbtype="int" required=false default=0 batcheditable=false ignoreChangesForVersioning=true;
	property name="segmentation_last_time_taken"  type="numeric" dbtype="int" required=false default=0 batcheditable=false ignoreChangesForVersioning=true renderer="taskTimeTaken";

	// helper formula fields for displays
	property name="kind" type="string" formula="case when ${prefix}filter_object is null then 'condition' else 'filter' end" autofilter="false" renderer="enumlabel" enum="rulesEngineConditionType" control="none";
	property name="applies_to" type="string" formula="coalesce( ${prefix}filter_object, ${prefix}context )" renderer="rulesEngineAppliesTo"  autofilter="false" control="none";
}