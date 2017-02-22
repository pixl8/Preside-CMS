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
			var formData       = $configuratorForm.serializeObject()
			  , $objectPickers = $configuratorForm.find( 'div.object-picker' );

			$objectPickers.each(function() {
				var $objectPicker = $( this )
				  , $labels       = $objectPicker.find( 'li.active-result' )
				  , $input        = $objectPicker.find( '.chosen-hidden-field' )
				  , inputValues   = $input.val().split();

				formData[ $input.attr( 'name' ) + '__label' ] = $labels.map( function() {
					var item = $( this ).data( 'item' );
					for( var i=0; i<inputValues.length; i++ ){
						if ( inputValues[ i ] == item.value ) {
							return item.text;
						}
					}
				} ).get().join( ', ' );
			});

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