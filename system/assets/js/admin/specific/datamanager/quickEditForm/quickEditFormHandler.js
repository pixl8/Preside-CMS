( function( $ ){

	var $quickEditForm = $( ".quick-edit-form" ).first()
	  , setupBehaviours, handleSubmission, editRecordToCallingControl, ajaxSuccessHandler, ajaxErrorHandler, resetForm, focusForm, getParentControl, submitForm, editAnother, showSuccessMessage;

	setupBehaviours = function(){
		$quickEditForm.submit( handleSubmission );
	};

	handleSubmission = function( e ){
		e.preventDefault();
		submitForm();
	};

	submitForm = function(){
		if ( $quickEditForm.valid() ) {
			$.ajax({
				  type    : "POST"
				, url     : $quickEditForm.attr( 'action' )
				, data    : $quickEditForm.serializeObject()
				, success : ajaxSuccessHandler
				, error   : ajaxErrorHandler
			});
		}
	};

	ajaxSuccessHandler = function( data ){
		if ( typeof data === "object" ) {
			if ( data.success ) {
				getParentControl().editSuccess( data.message || i18n.translateResource( "cms:datamanager.quick.edit.saved.confirmation" ) );
			} else if ( typeof data.validationResult === "object" ) {
				$quickEditForm.validate().showErrors( data.validationResult );
			}
		}
		// TODO error handling
	};

	ajaxErrorHandler = function(){
		// TODO error handling
	};


	getParentControl = function(){
		return window.presideObjectPicker;
	};

	focusForm = function(){
		$quickEditForm.find( "input,select,textarea" ).not( ":hidden" ).first().focus();
	};

	setupBehaviours();

	window.quickEdit = {
		  submitForm : submitForm
		, focusForm  : focusForm
	};


} )( presideJQuery );