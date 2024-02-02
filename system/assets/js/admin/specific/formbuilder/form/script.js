( function( $ ){
	var removalToggle     = "input.ace-switch[name='submission_remove_enabled']"
	  , $toggleFieldGroup = $( "input[name='submission_remove_after']" ).closest( ".form-group" )
	  , toggleRemovalFields;

	toggleRemovalFields = function() {
		var toggleChecked = $( removalToggle ).is(':checked');

		if ( toggleChecked ) {
			$toggleFieldGroup.show();
		} else {
			$toggleFieldGroup.hide();
		}
	};

	toggleRemovalFields();

	$( removalToggle ).on( "click", function(event) {
		toggleRemovalFields();
	});
} )( presideJQuery );