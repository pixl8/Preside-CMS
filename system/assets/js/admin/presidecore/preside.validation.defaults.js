( function( $ ){
	$.validator.setDefaults( {
		errorElement: 'div',
		errorClass: 'help-block',
		ignore: [],

		invalidHandler: function (event, validator) {
			var invalidElements = validator.invalidElements()
			  , tabId, i, $tab;

			for( i=0; i<invalidElements.length; i++ ){
				tabId = $( invalidElements[ i ] ).closest( '.tab-pane' ).attr( 'id' );
				$tab  = $( '.tabbable a[href="#' + tabId + '"]' );

				if ( $tab.length ) {
					$tab.closest( 'li' ).addClass( "error" );
					if ( i == 0 ) {
						$tab.tab( 'show' );
					}
				}
			}
		},

		highlight: function (e) {
			$(e).closest('.form-group').removeClass('has-info').addClass('has-error');
		},

		success: function (e) {
			$(e).closest('.form-group').removeClass('has-error').addClass('has-info');
			$(e).remove();
		},

		errorPlacement: function (error, element) {
			if(element.is(':checkbox') || element.is(':radio')) {
				var controls = element.closest('div[class*="col-"]');
				if(controls.find(':checkbox,:radio').length > 1) controls.append(error);
				else error.insertAfter(element.nextAll('.lbl:eq(0)').eq(0));
			}
			else if(element.is('.select2')) {
				error.insertAfter(element.siblings('[class*="select2-container"]:eq(0)'));
			}
			else if(element.is('.chosen-select')) {
				error.insertAfter(element.siblings('[class*="chosen-container"]:eq(0)'));
			}
			else error.insertAfter(element.parent());
		}
	} );
} )( presideJQuery );