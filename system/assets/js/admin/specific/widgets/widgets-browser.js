( function( $ ){
	var $widgetList = $( "#widget-list" );

	if ( $widgetList.length ) {
		var $form      = $widgetList.find( ".widget-search" )
		  , $searchBox = $form.find( "input.search:first" )
		  , followLiLink;

		// "List" plugin (see /admin/core/list.js - allows simple searching of html lists
		new List( 'widget-list', { valueNames : ['widget-title','widget-description'] } );

		// do not allow the search form to actually be submitted
		$form.submit( function( e ){ e.preventDefault(); } );

		// allow keyboard navigation into the results from the search box
		$searchBox.keydown( 'down', function( e ){ $widgetList.find( "li:visible" ).first().focus(); } );

		// when entire LIs are clicked or the enter key is pressed when they are focused, follow their links
		followLiLink = function( e, $li ){
			var $target = $li.find( "a:first" );

			if ( !$target.length ) {
				e.preventDefault();
			} else {
				$target.get(0).click();
			}
		};
		$widgetList.on( "click", "li", function( e ){ followLiLink( e, $( this ) ); } );
		$widgetList.find( "li" ).keydown( 'return', function( e ){ followLiLink( e, $( this ) ); } );
	}

} )( presideJQuery );