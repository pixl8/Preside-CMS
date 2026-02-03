/**
 * @presideService     true
 * @validationProvider true
 * @singleton          true
 */
component {

	property name="presideObjectService" inject="PresideObjectService";

	public any function init() {
		return this;
	}

	public boolean function responseMaxLength( required string fieldName, string value="", required string itemType, numeric length=0 ) validatorMessage="formbuilder:validation.responseMaxLength.default" {
		var values = ListToArray( arguments.value ?: "", Chr( 10 ) & Chr( 13 ) );

		if ( ArrayLen( values ) ) {
			var dataType = $getColdbox().renderViewlet( event="formbuilder.item-types.#arguments.itemType#.getQuestionDataType", args={
				  question      = arguments.data.id ?: ""
				, configuration = arguments.data    ?: {}
			} );

			if ( !arguments.length ) {
				arguments.length = Val( presideObjectService.getObjectPropertyAttribute( objectName="formbuilder_question_response", propertyName="#dataType#_response", attributeName="maxlength", defaultValue="" ) );
			}

			if ( arguments.length ) {
				for ( var value in values ) {
					if ( Len( value ) > arguments.length ) {
						return false;
					}
				}
			}
		}

		return true;
	}

	public string function responseMaxLength_js() {
		return "function(){ return true; }";
	}

}