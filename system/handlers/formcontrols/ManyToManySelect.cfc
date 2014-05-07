component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		if ( Len( Trim( viewletArgs.savedData.id ?: "" ) ) ) {
			var sourceObject = viewletArgs.sourceObject ?: "";

			viewletArgs.savedValue = presideObjectService.selectManyToManyData(
				  objectName   = sourceObject
				, propertyName = viewletArgs.name
				, id           = viewletArgs.savedData.id
				, selectFields = [ "#viewletArgs.name#.id" ]
			);

			viewletArgs.defaultValue = viewletArgs.savedValue = ValueList( viewletArgs.savedValue.id );
		}

		viewletArgs.object   = viewletArgs.relatedTo ?: "";
		viewletArgs.multiple = true;

		return renderFormControl( argumentCollection=viewletArgs, type="objectPicker", layout="" );
	}
}