/**
 * Pivot object for many-to-many relationship between benefits that represent
 * combined benefits (benefits that are based on a combination of other benefits)
 *
 * @nolabel
 */
component extends="preside.system.base.SystemPresideObject" displayName="Website user benefit" {

	property name="id"           deleted=true;
	property name="datecreated"  deleted=true;
	property name="datemodified" deleted=true;

	property name="source_website_benefit" relationship="many-to-one" relatedTo="website_benefit" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" uniqueindexes="sourcetarget|1" required=true;
	property name="target_website_benefit" relationship="many-to-one" relatedTo="website_benefit" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check" uniqueindexes="sourcetarget|2" required=true;
	property name="sort_order" type="numeric" dbtype="int";
}