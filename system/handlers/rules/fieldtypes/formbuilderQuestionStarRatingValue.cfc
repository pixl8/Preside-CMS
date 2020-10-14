/**
 * Handler for rules engine to retrieve a star rating field
 */
component {

	private string function renderConfiguredField( string value="", struct config={} ) {
		return NumberFormat( value );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		rc.delete( "value" );

		/*event.include( assetId="/js/frontend/formbuilder/" );
		event.include( assetId="/css/frontend/formbuilder/starRating/" );
		event.include( assetId="/js/frontend/formbuilder/starRating/" );
*/

		return renderFormControl(
			  argumentCollection = arguments.config
			, name               = "value"
			, type               = "select"
			, label              = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.starrating.config.label" )
			, context            = "formbuilder"
			, layout             = ""
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, values       = [0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5]
			, minValue     = "0"
			, maxValue     = "5"
			, step         = "0.5"
			, required     = true
			, layout         = "formcontrols.layouts.field"
		);

	}

}