/**
 * A store of flattened evaluated filter data. Used
 * with "segmented filters" system introduced in 10.19
 *
 * @versioned          false
 * @datamanagerEnabled false
 * @nolabel            true
 * @noid               true
 * @nodatemodified     true
 * @nodatecreated      true
 * @feature            rulesEngine
 */
component extends="preside.system.base.SystemPresideObject" displayName="Rules engine: filter data" {
	property name="filter"      required=true relationship="many-to-one" relatedto="rules_engine_condition" ondelete="cascade-if-no-cycle-check" indexes="record|1";
	property name="object_name" required=true type="string" dbtype="varchar" maxlength=200 indexes="objectname,record|2";
	property name="record_id"   required=true type="string" dbtype="varchar" maxlength=35 indexes="recordid,record|3";
	property name="holding_id"  required=true type="string" dbtype="varchar" maxlength=35 indexes="holdingid,record|4";
}