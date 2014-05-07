component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		viewletArgs.permissions = getSetting( name='globalPermissionKeys', defaultValue=[] );

		if ( Len( Trim( viewletArgs.savedData.id ?: "" ) ) ) {
			viewletArgs.savedValue = presideObjectService.selectData(
				  objectName   = "security_role_permission"
				, selectFields = [ "label" ]
				, filter       = { security_role = viewletArgs.savedData.id }
			);
		} else {
			viewletArgs.savedValue = QueryNew( 'label' );
		}
		viewletArgs.defaultValue = viewletArgs.savedValue = ValueList( viewletArgs.savedValue.label );

		return renderView( view="formcontrols/globalPermissionPicker/index", args=viewletArgs );
	}
}