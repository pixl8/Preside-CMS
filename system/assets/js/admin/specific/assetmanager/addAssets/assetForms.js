( function( $ ){

	var $pageContainer = $( '#add-asset-forms' )
	  , setupListeners, cancelAssetHandler, saveAssetHandler, deleteTempFileOnServer, removeAssetFormFromDom, processSaveResponse;

	cancelAssetHandler = function( e ){
		var $form        = $( this ).closest( "form" )
		  , $fileIdInput = $form.find( "input[name=fileid]" )
		  , fileId       = $fileIdInput.length && $fileIdInput.val();

		if ( fileId ) {
			deleteTempFileOnServer( fileId );
		}

		removeAssetFormFromDom( $form );

		e.preventDefault();
	};

	saveAssetHandler = function( e ){
		var $form = $( this );

		e.preventDefault();

		$.ajax({
			  type    : "POST"
			, url     : $form.attr( 'action' )
			, data    : $form.serialize()
			, success : function( data ) { processSaveResponse( data, $form ); }
			, error   : function() { processSaveResponse( {}, $form ); }
		});
	};

	processSaveResponse = function( response, $form ){
		if ( response.success ) {
			$.gritter.add( {
				  title      : i18n.translateResource( "cms:assetmanager.notifications.asset.uploaded.title" )
				, text       : i18n.translateResource( "cms:assetmanager.notifications.asset.uploaded.description", { data:[ response.title ] } )
				, class_name : "gritter-success"
			} );

			removeAssetFormFromDom( $form );
		} else {
			if ( response.validationResult ) {
				$form.data( 'validator' ).showErrors( response.validationResult );
			} else if ( response.title && response.message ) {
				$.gritter.add( {
					  title      : response.title
					, text       : response.message
					, class_name : "gritter-error"
				} );
			} else {
				$.gritter.add( {
					  title      : i18n.translateResource( "cms:assetmanager.add.asset.unexpected.error.title" )
					, text       : i18n.translateResource( "cms:assetmanager.add.asset.unexpected.error.message" )
					, class_name : "gritter-error"
				} );
			}
		}
	};

	deleteTempFileOnServer = function( fileId ){
		$.post( buildAdminLink( "assetmanager", "deleteTempFile" ), { fileid : fileId } );
	};

	removeAssetFormFromDom = function( $form ){
		$form.fadeOut( 400, function(){
			$form.remove();
			$form = $pageContainer.find( ".add-asset-form" ).first();

			if ( $form.length ) {
				$form.find( 'input:visible,select:visible,textarea:visible' ).first().focus();
			} else {
				$pageContainer.addClass( "processing-complete" );
				$pageContainer.find( ".back-btn" ).first().focus();
			}
		} );


	};

	setupListeners = function(){
		$pageContainer.on( "click", ".cancel-asset-btn", cancelAssetHandler );
		$pageContainer.on( "submit", ".add-asset-form", saveAssetHandler );
	};

	setupListeners();

} )( presideJQuery );