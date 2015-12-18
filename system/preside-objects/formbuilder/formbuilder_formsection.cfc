/**
 * @nolabel
 */
component {
	property name="form" relationship="many-to-one" relatedto="formbuilder_form" required=true uniqueindexes="formsection|1";
	property name="sort_order" type="numeric" dbtype="int" required=true uniqueindexes="formsection|2";
}