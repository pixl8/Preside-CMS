/**
 * @nowirebox true
 */
component accessors=true {
	property name="id"                type="string"  default="";
	property name="cfflowId"          type="string"  default="";
	property name="singleton"         type="boolean" default=false;
	property name="adminFlow"         type="boolean" default=false;
	property name="hideFromWidget"    type="boolean" default=false;
	property name="meta"              type="struct";
	property name="init"              type="struct";
	property name="layout"            type="struct";
	property name="preCancelHandler"  type="struct";
	property name="postCancelHandler" type="struct";
	property name="instRefConfig"     type="struct";
	property name="steps"             type="array";
	property name="configHash"        type="string";

	function getConfigHash() {
		if ( IsNull( variables.configHash ) ) {
			variables.configHash = Hash( Serialize( this ) );
		}

		return variables.configHash;
	}
}