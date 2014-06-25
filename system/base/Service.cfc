component output=false singleton=true accessors=true hint="I am a base Service object. All front-end services should extend me" {

	property name="presideObjectService" inject="presideObjectService";
	property name="logger"               inject="defaultLogger";

	public any function init() output=false {
		return this;
	}

<!--- shared utility methods --->
	private any function getPresideObject( required string objectName ) output=false {
		return _getPresideObjectService().getObject( objectName = arguments.objectName );
	}

	private boolean function presideObjectExists() output=false {
		return _getPresideObjectService().presideObjectExists( argumentCollection = arguments );
	}

	private any function fieldExists() output=false {
		return _getPresideObjectService().fieldExists( argumentCollection = arguments );
	}

	private any function dataExists() output=false {
		return _getPresideObjectService().dataExists( argumentCollection = arguments );
	}

	private any function deleteData() output=false {
		return _getPresideObjectService().deleteData( argumentCollection = arguments );
	}

	private any function insertData() output=false {
		return _getPresideObjectService().insertData( argumentCollection = arguments );
	}

	private any function updateData() output=false {
		return _getPresideObjectService().updateData( argumentCollection = arguments );
	}

	private any function selectData() output=false {
		return _getPresideObjectService().selectData( argumentCollection = arguments );
	}

	private any function getRelatedObjects() output=false {
		return _getPresideObjectService().getRelatedObjects( argumentCollection = arguments );
	}

// GETTERS AND SETTERS
	private any function _getPresideObjectService() output=false {
		return getPresideObjectService();
	}

	private any function _getLogger() output=false {
		return getLogger();
	}
}