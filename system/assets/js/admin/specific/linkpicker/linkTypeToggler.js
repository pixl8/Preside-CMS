( function( $ ){

	var $typeLinkList        = $( ".link-type-list" ).first()
	  , $linkTypeItems       = $( ".link-type-list" ).find( ".link-type" )
	  , $linkTypeInput       = $( "#link-picker-form input[name=type]" )
	  , $links               = $typeLinkList.find( ".link-type-link" )
	  , $toggleableFieldsets = $( "#tab-basic fieldset" )
	  , $basicTabLink        = $( "#link-picker-form a[href='#tab-basic']" )
	  , setActiveFieldset, deactivateFieldset, activateFieldset, initializeBehaviour;

	initializeBehaviour = function(){
		$links.click( function(e){
			e.preventDefault();
			$linkTypeItems.removeClass( "selected" );
			$( this ).closest( ".link-type" ).addClass( "selected" );

			setActiveFieldset();
			$basicTabLink.click();
		} );

		setActiveFieldset();
	};

	setActiveFieldset = function(){
		var $activeLink     = $typeLinkList.find( ".link-type.selected .link-type-link" )
		  , $targetFieldset = $( $activeLink.get(0).hash );

		$toggleableFieldsets.each( function(){
			var $fieldset = $( this );
			if ( $fieldset !== $targetFieldset ) {
				deactivateFieldset( $fieldset );
			}
		} );

		$linkTypeInput.val( $activeLink.data( 'linkType' ) );
		activateFieldset( $targetFieldset );
	};

	deactivateFieldset = function( $fieldset ){
		$fieldset.hide();
		$fieldset.find( "input,select,textarea" ).prop( 'disabled', true );
	};

	activateFieldset = function( $fieldset ){
		$fieldset.show();
		$fieldset.find( "input,select,textarea" ).prop( 'disabled', false );
	}

	initializeBehaviour();

} )( presideJQuery );