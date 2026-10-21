( function( $ ){

	var $form = $( ".listing-view-default-form" ).first()
	  , $scopeInput, $groupFilterFieldset, handleSubmission, ajaxSuccessHandler, ajaxErrorHandler
	  , enableSubmitButtons, submitForm, focusForm, getHost, showValidationErrors, getScope, toggleGroups;

	if ( !$form.length ) {
		return;
	}

	$scopeInput          = $form.find( "[name=scope]" );
	$groupFilterFieldset = $form.find( "#fieldset-group-filter" );

	getScope = function() {
		var $selected = $form.find( "[name=scope]:checked" );
		if ( $selected.length ) {
			return $selected.val();
		}
		return $scopeInput.val() || "";
	};

	toggleGroups = function() {
		if ( !$groupFilterFieldset.length ) {
			return;
		}
		if ( getScope() === "group" ) {
			$groupFilterFieldset.show();
		} else {
			$groupFilterFieldset.hide();
		}
	};

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

		if ( typeof data === "object" && data.success ) {
			if ( host && host.onSaved ) {
				host.onSaved( data );
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
		return window.listingViewDefaultHost;
	};

	$scopeInput.on( "change", toggleGroups );
	toggleGroups();
	$form.submit( handleSubmission );

	window.listingViewDefaultForm = {
		  submitForm : submitForm
		, focusForm  : focusForm
	};

} )( presideJQuery );
