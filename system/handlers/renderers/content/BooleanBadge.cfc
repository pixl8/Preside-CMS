component {

	property name="presideObjectService" inject="presideObjectService";

	public boolean function default( event, rc, prc, args={} ) {
		return IsTrue( args.data ?: "" );
	}

	public string function admin( event, rc, prc, args={} ) {
	
		var data           = args.data         ?: "";
		var objectName     = args.objectName   ?: "";
		var propertyName   = args.propertyName ?: "";
		var valueAttribute = "booleanBadgeUnknownValue";
		var styleAttribute = "booleanBadgeUnknownStyle";
		
		if ( IsBoolean( data ) ) {
			valueAttribute = data ? "booleanBadgeTrueValue" : "booleanBadgeFalseValue";
			styleAttribute = data ? "booleanBadgeTrueStyle" : "booleanBadgeFalseStyle";
		}
		
		var booleanBadgeValue = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName=valueAttribute );
		booleanBadgeValue = translateResource( uri="preside-objects.#objectName#:field.#propertyName#.#valueAttribute#", defaultValue=booleanBadgeValue );
		
		if ( isEmpty( booleanBadgeValue ) ) {
			return "";
		}
		
		var booleanBadgeStyle = presideObjectService.getObjectPropertyAttribute( objectName=objectName, propertyName=propertyName, attributeName=styleAttribute, defaultValue="info" );
		booleanBadgeStyle = translateResource( uri="preside-objects.#objectName#:field.#propertyName#.#styleAttribute#", defaultValue=booleanBadgeStyle );
		
		return '<span class="badge badge-pill badge-#booleanBadgeStyle#">#booleanBadgeValue#</span>';
	}

}