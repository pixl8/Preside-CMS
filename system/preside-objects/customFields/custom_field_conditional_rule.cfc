/**
 * @versioned                       false
 * @datamanagerEnabled              true
 * @datamanagerGridFields           label_text,filter
 * @datamanagerHiddenGridFields     colour
 * @datamanagerSortable             true
 * @datamanagerSortField            sort_order
 * @datamanagerDefaultSortOrder     sort_order,label_text
 * @datamanagerDisallowedOperations clone,batchedit,view
 * @labelfield                      label_text
 * @feature                         customFields and rulesEngine
 */
component displayname="Custom field conditional rule" extends="preside.system.base.SystemPresideObject" {
	property name="field"      relationship="many-to-one" relatedto="custom_field" required=true ondelete="cascade" indexes="field";
	property name="filter"     relationship="many-to-one" relatedto="rules_engine_condition" required=true ondelete="cascade" control="customFieldFilterPicker";
	property name="label_text" type="string"  dbtype="varchar" maxlength=100 required=true renderer="customFieldConditionalLabel";
	property name="colour"     type="string"  dbtype="varchar" maxlength=20  required=false control="simpleColourPicker";
	property name="sort_order" type="numeric" dbtype="int" required=false default=0 indexes="sortorder";
}
