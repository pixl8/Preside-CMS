( function( $ ){

	var $quickAddForm = $( ".quick-add-form" ).first()
	  , setupBehaviours, handleSubmission, addRecordToCallingControl, ajaxSuccessHandler, ajaxErrorHandler, resetForm, focusForm, getParentControl, submitForm, addAnother, showSuccessMessage;

	setupBehaviours = function(){
		$quickAddForm.submit( handleSubmission );
	};

	handleSubmission = function( e ){
		e.preventDefault();
		submitForm();
	};

	submitForm = function(){
		if ( $quickAddForm.valid() ) {
			$.ajax({
				  type    : "POST"
				, url     : $quickAddForm.attr( 'action' )
				, data    : $quickAddForm.serializeObject()
				, success : ajaxSuccessHandler
				, error   : ajaxErrorHandler
			});
		}
	};

	ajaxSuccessHandler = function( data ){
		if ( typeof data === "object" ) {
			if ( data.success && data.value ) {
				addRecordToCallingControl( data.value, data.label );
				if ( addAnother() ) {
					resetForm();
					focusForm();
					showSuccessMessage( data.message || i18n.translateResource( "cms:quicklink.add.added.confirmation" ) );
				} else {
					getParentControl().closeQuickAddDialog();
				}
				return;
			} else if ( typeof data.validationResult === "object" ) {
				$quickAddForm.validate().showErrors( data.validationResult );
			}
		}

		// TODO error handling
	};

	ajaxErrorHandler = function(){
		// TODO error handling
	};


	addRecordToCallingControl = function( value, label ){
		getParentControl().addRecordToControl( value, label );
	};

	getParentControl = function(){
		return window.presideObjectPicker;
	};

	addAnother = function(){
		return $quickAddForm.find( "input[name='_addAnother']:checked" ).length;
	};

	showSuccessMessage = function( message ){
		$.gritter.add({
			  title      : i18n.translateResource( "cms:info.notification.title" )
			, text       : message
			, class_name : "gritter-success"
			, sticky     : false
		});
	};

	resetForm = function(){
		$quickAddForm.trigger( "reset" );
	};

	focusForm = function(){
		$quickAddForm.find( "input,select,textarea" ).not( ":hidden" ).first().focus();
	};


	setupBehaviours();

	window.quickAdd = {
		  submitForm : submitForm
		, focusForm  : focusForm
	};


} )( presideJQuery );