( function( $ ){

	$("body").on( "click", ".confirmation-prompt", function( e ) {
		var $link = $( this )
		  , title;

		e.preventDefault();

		if ( !$link.data( "confirmationPrompt" ) ) {
			title = $link.data( "title" ) || $link.attr("title");
			title = title.charAt(0).toLowerCase() + title.slice(1);
			var hasChildren = $link.attr( "data-has-children" );
			if( hasChildren > 0 ) {
				$link.data( "confirmationPrompt",  i18n.translateResource( "cms:child.confirmation.prompt", { data:[hasChildren,title] } ) );
			} else {
				$link.data( "confirmationPrompt",  i18n.translateResource( "cms:confirmation.prompt", { data:[title] } ) );
			}
		}

		presideBootbox.confirm( $link.data( "confirmationPrompt" ), function( confirmed ) {
			if ( confirmed ) {
				if ( $link.get(0).form ) {
					$( $link.get(0).form ).submit();
				} else {
					document.location = $link.attr('href');
				}
			}
		});
	});

} )( presideJQuery );