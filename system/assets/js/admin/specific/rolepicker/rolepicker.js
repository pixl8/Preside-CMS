( function( $ ){
	var toggleAreaSection = function( $row, shouldDisplay ) {
		if ( shouldDisplay ) {
			$row.removeClass( "collapsed" );
			$row.find( ".collapsible-header-icon" ).removeClass( "fa-chevron-right" );
			$row.find( ".collapsible-header-icon" ).addClass( "fa-chevron-down" );

			$( ".collapsible-content.group-" + $row.data( "groupId" ) + "" ).removeClass( "hide" );
			$( ".collapsible-content.group-" + $row.data( "groupId" ) + "" ).show();
		} else {
			$row.addClass( "collapsed" );
			$row.find( ".collapsible-header-icon" ).removeClass( "fa-chevron-down" );
			$row.find( ".collapsible-header-icon" ).addClass( "fa-chevron-right" );

			$( ".collapsible-content.group-" + $row.data( "groupId" ) + "" ).addClass( "hide" );
			$( ".collapsible-content.group-" + $row.data( "groupId" ) + "" ).hide();
		}
	};

	$( "a.collapsible-header-link" ).on( "click", function(event) {
		event.preventDefault();

		toggleAreaSection( $(this), $(this).hasClass( "collapsed" ) );
	} );

	$( "div.collapsible-content" ).each(function(index, el) {
		var $checked = $(this).find("input.ace-switch:checked");

		if ($checked.length > 0) {
			toggleAreaSection( $( 'a.collapsible-header-link[data-group-id="' + $(this).data( "parentGroupId" ) + '"]' ), true );
		}
	});
})( presideJQuery );