( function( $ ){

	$( "input.all-topics" ).each( function(){
		var $allTopicsCheckbox    = $( this )
		  , $form                 = $allTopicsCheckbox.closest( "form" )
		  , $otherTopics          = $form.find( "input.topic-checkbox" )
		  , $otherTopicContainers = $form.find( ".topic-checkbox-label" )
		  , toggle;

		toggle = function(){
			if ( $allTopicsCheckbox.is( ":checked" ) ) {
				$otherTopicContainers.addClass( "grey" );
				$otherTopicContainers.addClass( "disabled" );
				$otherTopics.prop( "disabled", true );
			} else {
				$otherTopicContainers.removeClass( "grey" );
				$otherTopicContainers.removeClass( "disabled" );
				$otherTopics.prop( "disabled", false );
			}
		};

		$allTopicsCheckbox.on( "click", toggle );

		toggle();

	} );

} )( presideJQuery );