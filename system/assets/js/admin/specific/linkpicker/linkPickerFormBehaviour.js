( function( $ ){

	var $form                = $( "#link-picker-form" )
	  , $typeLinkList        = $( ".link-type-list" ).first()
	  , $linkTypeItems       = $( ".link-type-list" ).find( ".link-type" )
	  , $linkTypeInput       = $form.find( "input[name=type]" )
	  , $links               = $typeLinkList.find( ".link-type-link" )
	  , $toggleableFieldsets = $( "#tab-basic fieldset" ).not( "#fieldset-standard" )
	  , $basicTabLink        = $form.find( "a[href='#tab-basic']" )
	  , $protocolField       = $form.find( "#protocol" ).length ? $form.find( "#protocol" ) : $form.find( "#external_protocol" )
	  , $addressField        = $form.find( "input[name='address']" ).length ? $form.find( "input[name='address']" ) : $form.find( "input[name='external_address']" )
	  , setActiveFieldset, deactivateFieldset, activateFieldset, initializeBehaviour, setupAnchors, autosetProtocol;

	initializeBehaviour = function(){
		$links.click( function(e){
			e.preventDefault();
			$linkTypeItems.removeClass( "selected" );
			$( this ).closest( ".link-type" ).addClass( "selected" );

			setActiveFieldset();
			$basicTabLink.click();
		} );

		$addressField.on( "change", autosetProtocol );

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

	autosetProtocol = function(){
		var addressValue = $addressField.val();
		var regex        = /^[a-z]+\:\/\//;
		var match        = addressValue.match( regex );

		if ( match !== null && match.length === 1 ) {
			var protocol = match[ 0 ];

			$protocolField.data( 'uberSelect' ).select( protocol, protocol );
			$addressField.val( addressValue.replace( regex, '' ) );
		}
	};

	setupAnchors();
	initializeBehaviour();

} )( presideJQuery );