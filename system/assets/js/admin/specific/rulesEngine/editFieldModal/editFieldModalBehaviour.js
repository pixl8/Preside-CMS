( function( $ ){

	var $form=$( ".edit-field-form" ).first()
	  , submitForm, ajaxSuccessHandler, ajaxErrorHandler, save;

	submitForm = function(){
		if ( $form.length ) {
			$.ajax({
				  type    : "POST"
				, url     : $form.attr( 'action' )
				, data    : $form.serializeObject()
				, success : ajaxSuccessHandler
				, error   : ajaxErrorHandler
			});
		}
	};

	ajaxSuccessHandler = function( result ){
		if ( result.success ) {
			save( result.value || "" );
		} else {
			// TODO, capture and deal with errors (validation, for example)
		}
	};

	ajaxErrorHandler = function(){
		// TODO, capture and deal with errors (validation, for example)
	};

	save = function( value ){
		rulesEngineCondition.saveFieldValue( $field, value );
	};


	window.rulesEngineDialog = { submitForm : submitForm };

	$form.on( "submit", function( e ){
		e.preventDefault();
		submitForm();
	} );

} )( presideJQuery );