( function( $ ){
	$( ".with-override-option" ).each( function(){
		var $container        = $( this )
		  , $overrideCheckbox = $container.find( ".override-checkbox > input" )
		  , $control          = $container.find( ".control" )
		  , $label            = $container.find( ".control-label" ).not( ".override-checkbox" );

		var enableOverride = function( e ){
			$overrideCheckbox.prop( "checked", true );
		};

		$control.on( "click", enableOverride );
		$control.on( "change", ".form-control", enableOverride );
		$label.on( "click", enableOverride );
	} );

} )( presideJQuery );