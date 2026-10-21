( function( $ ){

	var $form = $( ".listing-view-save-form" ).first()
	  , handleSubmission, ajaxSuccessHandler, ajaxErrorHandler, enableSubmitButtons, submitForm, focusForm, getHost, showValidationErrors;

	if ( !$form.length ) {
		return;
	}

	handleSubmission = function( e ){
		e.preventDefault();
		submitForm();
	};

	submitForm = function(){
		if ( $form.valid() ) {
			$.ajax({
				  type    : "POST"
				, url     : $form.attr( "action" )
				, data    : $form.serializeObject()
				, success : ajaxSuccessHandler
				, error   : ajaxErrorHandler
			});
		}
	};

	showValidationErrors = function( errors ) {
		var mapped = {};

		if ( typeof errors !== "object" || errors === null ) {
			return;
		}

		$.each( errors, function( name, message ) {
			if ( name && $form.find( "[name='" + name + "']" ).length ) {
				mapped[ name ] = message;
			}
		} );

		if ( !$.isEmptyObject( mapped ) ) {
			$form.validate().showErrors( mapped );
		}
	};

	ajaxSuccessHandler = function( data ){
		var host = getHost();

		if ( typeof data === "object" && data.success && data.view ) {
			if ( host && host.onSaved ) {
				host.onSaved( data.view );
			}
			if ( host && host.close ) {
				host.close();
			}
			return;
		}

		if ( typeof data === "object" && typeof data.validationResult === "object" ) {
			showValidationErrors( data.validationResult );
		}
		enableSubmitButtons();
	};

	ajaxErrorHandler = function(){
		enableSubmitButtons();
	};

	enableSubmitButtons = function(){
		$form.find( "button[type=submit], input[type=submit]" ).prop( "disabled", false );
	};

	focusForm = function(){
		$form.find( "input,select,textarea" ).not( ":hidden" ).first().focus();
	};

	getHost = function(){
		return window.listingViewSaveHost;
	};

	$form.submit( handleSubmission );

	window.listingViewSaveForm = {
		  submitForm : submitForm
		, focusForm  : focusForm
	};

} )( presideJQuery );
