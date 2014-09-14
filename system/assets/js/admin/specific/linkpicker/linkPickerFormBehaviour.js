( function( $ ){

	var $typeLinkList        = $( ".link-type-list" ).first()
	  , $linkTypeItems       = $( ".link-type-list" ).find( ".link-type" )
	  , $linkTypeInput       = $( "#link-picker-form input[name=type]" )
	  , $links               = $typeLinkList.find( ".link-type-link" )
	  , $toggleableFieldsets = $( "#tab-basic fieldset" ).not( "#fieldset-title" )
	  , $basicTabLink        = $( "#link-picker-form a[href='#tab-basic']" )
	  , setActiveFieldset, deactivateFieldset, activateFieldset, initializeBehaviour, setupAnchors;

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

	setupAnchors = function(){
		var anchors = cfrequest.anchors || []
		  , $anchorsSelectBox = $( '#anchor' )
		  , currentValue = $anchorsSelectBox.data( "value" ) || ""
		  , i, anchorCount;

		if ( typeof anchors === "string" ) {
			anchors = anchors.split( "," );
		}
		if ( currentValue.length && anchors.indexOf( currentValue ) === -1 ) {
			anchors.push( currentValue );
		}

		anchorCount = anchors.length;

		if ( !anchorCount ) {
			$anchorsSelectBox.attr( "data-placeholder", i18n.translateResource( "cms:ckeditor.linkpicker.no.anchors" ) )
		} else {
			$anchorsSelectBox.append( '<option value=""></option>' );
			for( i=0; i < anchorCount; i++ ){
				$anchorsSelectBox.append( '<option value="' + anchors[i] + '">' + anchors[i] + '</option>' );
			}
		}

		// rebuild the uber select with the new options
		$anchorsSelectBox.uberSelect( 'destroy' );
		$anchorsSelectBox.uberSelect( { allow_single_deselect : true, inherit_select_classes : true } );
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

	setupAnchors();
	initializeBehaviour();

} )( presideJQuery );