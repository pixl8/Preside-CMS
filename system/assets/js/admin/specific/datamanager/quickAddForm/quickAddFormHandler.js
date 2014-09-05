( function( $ ){

	var $quickAddForm = $( ".quick-add-form" ).first()
	  , setupBehaviours, handleSubmission, addRecordToCallingControl, ajaxSuccessHandler, ajaxErrorHandler, resetForm, getParentControl, submitForm, addAnother;

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

	resetForm = function(){
		// TODO
	};


	setupBehaviours();

	window.quickAdd = {
		submitForm : submitForm
	};


} )( presideJQuery );