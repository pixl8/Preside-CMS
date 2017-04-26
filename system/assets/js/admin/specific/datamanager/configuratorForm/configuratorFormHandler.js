( function( $ ){

	var $configuratorForm = $( ".configurator-form" ).first()
	  , setupBehaviours, handleSubmission, addRecordToCallingControl, focusForm, getParentControl, submitForm;

	setupBehaviours = function(){
		$configuratorForm.submit( handleSubmission );
	};

	handleSubmission = function( e ){
		e.preventDefault();
		submitForm();
	};

	submitForm = function(){
		if ( $configuratorForm.valid() ) {
			$configuratorForm.find(':checkbox:not(:checked)').attr('value', '0').prop('checked', true);
			var formData = $configuratorForm.serializeObject();
			addRecordToCallingControl( formData );
			getParentControl().closeConfiguratorDialog();
		}
	};

	addRecordToCallingControl = function( recordData ){
		getParentControl().addRecordToControl( recordData );
	};

	getParentControl = function(){
		return window.presideObjectConfigurator;
	};

	focusForm = function(){
		$configuratorForm.find( "input,select,textarea" ).not( ":hidden" ).first().focus();
	};


	setupBehaviours();

	window.configurator = {
		  submitForm : submitForm
		, focusForm  : focusForm
	};


} )( presideJQuery );