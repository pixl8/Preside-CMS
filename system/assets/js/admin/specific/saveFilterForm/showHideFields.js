( function( $ ){

	var activeFormClass = $( ".quick-add-form" ).length ? ".quick-add-form" : ".edit-object-form";
	var $form           = $( activeFormClass );

	if ( $form.length ) {
		var $groupFilterFieldset  = $form.find( "#fieldset-group-filter" )
		  , $globalFilterFieldset = $form.find( "#fieldset-global-filter" )
		  , getRadioValue
		  , getFilterScope
		  , enableFieldsetsBasedOnFilterScope;

		getRadioValue = function( name ) {
			var $selectedRadio = $form.find( "[name=" + name + "]:checked" );

			if ( $selectedRadio.length ) {
				return $selectedRadio.val();
			}

			return "";
		}
		getFilterScope = function(){ return getRadioValue( "rule_scope" ) };

		enableFieldsetsBasedOnFilterScope = function(){
			var filterScope = getFilterScope();

			switch( filterScope ) {
				case "individual":
					$groupFilterFieldset.hide();
					$globalFilterFieldset.hide();
				break;

				case "group":
					$groupFilterFieldset.show();
					$globalFilterFieldset.hide();
				break;

				default:
					$groupFilterFieldset.hide();
					$globalFilterFieldset.show();
			}
		};

		$form.on( "click", "[name=rule_scope]", enableFieldsetsBasedOnFilterScope );

		enableFieldsetsBasedOnFilterScope();
	}

} )( presideJQuery );