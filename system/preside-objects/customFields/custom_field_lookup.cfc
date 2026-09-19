/**
 * @versioned                       false
 * @datamanagerEnabled              true
 * @datamanagerGridFields           label,value,sort_order
 * @datamanagerDefaultSortOrder     sort_order,label
 * @datamanagerDisallowedOperations clone,batchedit,view
 * @labelfield                      label
 * @feature                         customFields
 */
component displayname="Custom field lookup" extends="preside.system.base.SystemPresideObject" {
	property name="field"      relationship="many-to-one" relatedto="custom_field" required=true uniqueindexes="fieldvalue|1" ondelete="cascade";
	property name="value"      type="string"  dbtype="varchar" maxlength=100 required=true uniqueindexes="fieldvalue|2";
	property name="label"      type="string"  dbtype="varchar" maxlength=200 required=true;
	property name="sort_order" type="numeric" dbtype="int" required=false default=0 indexes="sortorder";
}
