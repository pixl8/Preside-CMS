component {
	public any function init() {
		return this;
	}

	public void function preInsertObjectData( event, interceptData ) {
		var objectName = arguments.interceptData.objectName ?: "";
		var data       = arguments.interceptData.data ?: {};

		if ( objectName == "rules_engine_condition" && event.isAdminUser() && StructKeyExists( data, "rule_scope" ) ) {
			var nonGlobal       = [ "group", "individual" ];
			var isPrivateFilter = arrayFindNoCase( nonGlobal, data.rule_scope );

			if ( IsTrue( isPrivateFilter ) || Len( data.user_groups ?: "" ) ) {
				data.owner        = event.getAdminUserId();
				data.is_favourite = false;
			} else {
				data.allow_group_edit = false;
			}
		}
	}
}
