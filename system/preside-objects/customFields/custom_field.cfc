/**
 * @versioned                     false
 * @datamanagerEnabled            true
 * @datamanagerGridFields         label,target_object,kind,data_type,active,datemodified
 * @datamanagerSearchFields       label,key,target_object
 * @datamanagerSortable           true
 * @datamanagerSortField          sort_order
 * @datamanagerDefaultSortOrder   sort_order,label
 * @datamanagerDisallowedOperations clone
 * @labelfield                    label
 * @feature                       customFields
 */
component displayname="Custom field" extends="preside.system.base.SystemPresideObject" {
	property name="id"            type="numeric" dbtype="bigint" generator="increment";
	property name="key"           type="string" dbtype="varchar" maxlength=50  required=true uniqueindexes="objectkey|2" format="regex:^[a-z][a-z0-9_]*$";
	property name="label"         type="string" dbtype="varchar" maxlength=200 required=true indexes="label";
	property name="help_text"     type="string" dbtype="text"    required=false;
	property name="kind"          type="string" dbtype="varchar" maxlength=30  required=true enum="customFieldKind" indexes="kind";
	property name="target_object" type="string" dbtype="varchar" maxlength=100 required=true uniqueindexes="objectkey|1" indexes="targetobject" control="customFieldTargetObject";
	property name="slot"          type="string" dbtype="varchar" maxlength=50  required=false default="custom" control="customFieldSlot";
	property name="sort_order"      type="numeric" dbtype="int"     required=false default=0;
	property name="active"          type="boolean" dbtype="boolean" required=false default=false renderer="booleanBadge";
	property name="data_exportable" type="boolean" dbtype="boolean" required=false default=true;
	property name="batch_editable"  type="boolean" dbtype="boolean" required=false default=true;

	property name="data_type" type="string" dbtype="varchar" maxlength=30 required=false enum="customFieldDataType";
	property name="renderer"  type="string" dbtype="varchar" maxlength=50 required=false;
	property name="type_config" type="string" dbtype="text" required=false autofilter=false adminRenderer="none";
	property name="related_object" type="string" dbtype="varchar" maxlength=100 required=false control="dataManagerObjectPicker";

	property name="aggregate_property"       type="string" dbtype="varchar" maxlength=100 required=false control="customFieldAggregateProperty";
	property name="aggregate_function"       type="string" dbtype="varchar" maxlength=20  required=false enum="customFieldAggregateFunction";
	property name="aggregate_value_property" type="string" dbtype="varchar" maxlength=100 required=false control="customFieldAggregateValueProperty";
	property name="aggregate_filter"         relationship="many-to-one" relatedto="rules_engine_condition" required=false ondelete="set-null-if-no-cycle-check" control="customFieldAggregateFilterPicker" feature="rulesEngine";

	property name="related_data_relationship" type="string" dbtype="varchar" maxlength=255 required=false control="customFieldRelatedDataTree";
	property name="related_data_property"     type="string" dbtype="varchar" maxlength=100 required=false control="hidden";

	property name="lookups"            relationship="one-to-many" relatedto="custom_field_lookup"            relationshipKey="field";
	property name="conditional_rules"  relationship="one-to-many" relatedto="custom_field_conditional_rule"  relationshipKey="field" feature="rulesEngine";
	property name="lookup_count"             type="numeric" formula="Count( ${prefix}lookups.id )"            autofilter=false adminRenderer="none";
	property name="conditional_rule_count"   type="numeric" formula="Count( ${prefix}conditional_rules.id )"  autofilter=false adminRenderer="none" feature="rulesEngine";
}
