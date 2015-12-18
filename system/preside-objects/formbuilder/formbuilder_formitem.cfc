/**
 * @nolabel
 */
component {
	property name="section" relationship="many-to-one" relatedto="formbuilder_formsection" required=true uniqueindexes="formitem|1";

	property name="sort_order"    type="numeric" dbtype="int"     required=true uniqueindexes="formitem|2";
	property name="item_type"     type="string"  dbtype="varchar" required=true maxlength=100;
	property name="configuration" type="string"  dbtype="text"    required=false;
}