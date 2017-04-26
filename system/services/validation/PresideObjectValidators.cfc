component output=false validationProvider=true singleton=true {

	/**
	 * @presideObjectService.inject PresideObjectService
	 */
	public any function init( required any presideObjectService ) output=false {
		_setPresideObjectService( arguments.presideObjectService );
		return this;
	}

	public boolean function presideObjectUniqueIndex( required string fieldName, struct data={}, required string objectName, required string fields ) output=false validatorMessage="cms:validation.presideObjectUniqueIndex.default" {
		var pobjService  = _getPresideObjectService();
		var dbAdapter    = pobjService.getDbAdapterForObject( arguments.objectName );
		var filter       = "";
		var filterParams = {};
		var field        = "";
		var delimiter    = "";

		if ( not pobjService.objectExists( arguments.objectName ) ) {
			return false;
		}

		if ( StructKeyExists( arguments.data, "id" ) and Len( Trim( arguments.data.id ) ) ) {
			filter               = "id != :id";
			filterParams[ "id" ] = arguments.data.id;
			delimiter            = " and ";
		}

		for( field in ListToArray( arguments.fields ) ){
			if ( !StructKeyExists( arguments.data, field ) || !Len( Trim( arguments.data[ field ] ) ) ) {
				return true; // yes! a unique index should be by-passed when any field is null
			}

			filter &= delimiter & "#dbAdapter.escapeEntity( field )# = :#field#";
			filterParams[ field ]  = arguments.data[ field ];

			delimiter = " and ";
		}

		return not pobjService.dataExists(
			  objectName   = arguments.objectName
			, filter       = filter
			, filterParams = filterParams
		);
	}

	public string function presideObjectUniqueIndex_js() output=false {
		return "function(){ return true; }";
	}

	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}
}