/**
 * Object to represent a queue of records that require batch update operation
 * that can be picked from when processing the update
 *
 * @nolabel        true
 * @noid           true
 * @nodatemodified true
 * @versioned      false
 */
component extends="preside.system.base.SystemPresideObject" {
    property name="queue_id"  type="string"  dbtype="varchar" maxlength=35 required=true indexes="queueid,recordqueue|1";
    property name="record_id" type="string"  dbtype="varchar" maxlength=35 required=true indexes="recordid,recordqueue|2";
}