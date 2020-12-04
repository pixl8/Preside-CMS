( function( $ ){

	$( "body" ).on( "click", ".confirmation-prompt", function( e ) {
		e.preventDefault();

		var $link = $( this )
		  , title = ""
		;

		if( !$link.data( "confirmationPrompt" ) ) {
			title = $link.data( "title" ) || $link.attr( "title" );
			title = title.charAt( 0 ).toLowerCase() + title.slice( 1 );
			var hasChildren = $link.attr( "data-has-children" );
			if( hasChildren > 0 ) {
				$link.data( "confirmationPrompt",  i18n.translateResource( "cms:child.confirmation.prompt", { data:[ hasChildren, title ] } ) );
			} else {
				$link.data( "confirmationPrompt",  i18n.translateResource( "cms:confirmation.prompt", { data:[ title ] } ) );
			}
		}

		var $message = $( "<div class=\"form-group\"><label>" + $link.data( "confirmationPrompt" ) + "</label></div>" )
		  , $input   = $( "<input class=\"bootbox-input form-control\" autocomplete=\"off\" type=\"text\" />" )
		  , match    = ""
		;

		if( typeof $link.data( "confirmation-match" ) !== "undefined" ) {
			match =  $link.data( "confirmation-match" );

			$message
				.append( "<p class=\"help-block\">" + i18n.translateResource( "cms:confirmation.prompt.please.type.message", { data:[ "<code>" + match + "</code>" ] } ) + "</p>" )
				.append( $input )
			;
		}

		presideBootbox.dialog( {
			  title   : "Confirmation"
			, message : $message
			, buttons : {
				  cancel  : {
				  	label: i18n.translateResource( "cms:confirmation.prompt.cancel.button" )
				  }
				, confirm : {
					  label: i18n.translateResource( "cms:confirmation.prompt.confirm.button" )
					, callback: function() {
						var confirmed = false;

						if( match.length ) {
							if( $input.val() === match ) {
								confirmed = true;
								$message.removeClass( "has-error" );
							}
							else {
								$message.addClass( "has-error" );
							}
						}
						else {
							confirmed = true;
						}

						if( confirmed ) {
							if ( $link.get( 0 ).form ) {
								$( $link.get( 0 ).form ).submit();
							}
							else {
								document.location = $link.attr( "href" );
							}
						}

						return false;
					}
				}
			}
		} );
	});

} )( presideJQuery );