( function( $ ){

	var $quickAddForm = $( ".quick-add-form" ).first()
	  , setupBehaviours, handleSubmission, addRecordToCallingControl, ajaxSuccessHandler, ajaxErrorHandler, resetForm, getParentControl, submitForm, addAnother, showSuccessMessage;

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
			if ( data.success && data.recordId ) {
				addRecordToCallingControl( data.recordId );
				if ( addAnother() ) {
					resetForm();
					showSuccessMessage( data.message || i18n.translateResource( "cms:datamanager.quick.add.added.confirmation" ) );
				} else {
					getParentControl().closeQuickAddDialog();
				}
				return;
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
		return uberSelectWithQuickAdd;
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
		$quickAddForm.find( "input,select,textarea" ).not( ":hidden" ).first().focus();
	};


	setupBehaviours();

	window.quickAdd = {
		submitForm : submitForm
	};


} )( presideJQuery );