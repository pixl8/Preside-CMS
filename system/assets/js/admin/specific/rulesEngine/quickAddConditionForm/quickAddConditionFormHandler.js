( function( $ ){

	var $quickAddForm = $( ".quick-add-form" ).first()
	  , $promptForm, setupBehaviours, handleSubmission, addRecordToCallingControl, ajaxSuccessHandler, ajaxErrorHandler, resetForm, focusForm, getParentControl, submitForm, addAnother, showSuccessMessage;

	setupBehaviours = function(){
		$quickAddForm.submit( handleSubmission );
	};

	handleSubmission = function( e ){
		e.preventDefault();
		submitForm();
	};

	submitForm = function(){
		if ( typeof $promptForm !== "undefined" ) {
			$.ajax({
				  type    : "POST"
				, url     : $promptForm.attr( 'action' )
				, data    : $promptForm.serializeObject()
				, success : ajaxSuccessHandler
				, error   : ajaxErrorHandler
			});
		} else if ( $quickAddForm.valid() ) {
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
			if ( data.success && data.recordId ) {
				addRecordToCallingControl( data.recordId );
				if ( addAnother() ) {
					resetForm();
					focusForm();
					showSuccessMessage( data.message || i18n.translateResource( "cms:datamanager.quick.add.added.confirmation" ) );
				} else {
					getParentControl().closeQuickAddDialog();
				}
				return;
			} else if ( typeof data.validationResult === "object" ) {
				$quickAddForm.validate().showErrors( data.validationResult );
			} else if ( typeof data.convertPrompt === "string" ) {
				var $prompt = $( data.convertPrompt );

				$promptForm = $prompt.find( "form:first" );
				$promptForm.on( "click", "button", function( e ){
					e.preventDefault();
					$( '<input type="hidden" name="convertAction" value="' + $( this ).val() + '">' ).appendTo( $promptForm );
					submitForm();
				} )

				$quickAddForm.hide().after( $prompt );

			}
		}

		// TODO error handling
	};

	ajaxErrorHandler = function(){
		// TODO error handling
	};


	addRecordToCallingControl = function( recordId ){
		getParentControl().addRecordToControl( recordId );
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