/**
 * Object to represent a queue of records that require some kind of batch operation
 *
 * @nolabel        true
 * @noid           true
 * @nodatemodified true
 * @versioned      false
 * @feature        admin
 */
component extends="preside.system.base.SystemPresideObject" displayName="Batch operation queue" {
    property name="queue_id"  type="string"  dbtype="varchar" maxlength=35 required=true indexes="queueid,recordqueue|1";
    property name="record_id" type="string"  dbtype="varchar" maxlength=35 required=true indexes="recordid,recordqueue|2";
}