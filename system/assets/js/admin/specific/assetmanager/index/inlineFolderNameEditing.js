( function( $ ){

	var $listingTable = $( '#asset-listing-table' )
	  , toggleRenameForm
	  , setupEventListeners
	  , saveFolderName
	  , processSaveResponse;

	setupEventListeners = function(){
		$listingTable.on( "click", ".rename-folder", toggleRenameForm );
		$listingTable.on( "keydown", ".edit-folder-form input[name=label]", "esc", toggleRenameForm );
		$listingTable.on( "submit", ".edit-folder-form", saveFolderName );
		$listingTable.on( 'focus', 'tr', function(){ $( this ).addClass( 'focus' ); } );
		$listingTable.on( 'blur', 'tr', function(){ $( this ).removeClass( 'focus' ); } );
		$listingTable.on( 'keydown', 'tr.focus', 'return', function(){ $( this ).click(); } );
	};

	toggleRenameForm = function( e, forceHide ){
		var $parentRow = $( this ).closest( "tr" )
		  , $input     = $parentRow.find( ".edit-folder-form input[name=label]" );

		e.preventDefault();
		$parentRow.siblings().removeClass( "editing" );
		if ( forceHide ) {
			$parentRow.removeClass( "editing" );
		} else {
			$parentRow.toggleClass( "editing" );
		}

		if ( $input.is( ":visible" ) ) {
			// using a timeout to avoid key press trigger effecting the content of input box
			setTimeout( function(){
				$input.focus();
			}, 1 );
		}
	};

	saveFolderName = function( e ){
		var $form         = $( this )
		  , $input        = $form.find( "input[name=label]" )
		  , $folderNameEl = $form.closest( "tr" ).find( ".folder-name" )
		  , url           = $form.attr( 'action' )
		  , newVal        = $input.val()
		  , originalVal   = $folderNameEl.html();

		e.preventDefault();

		if ( $.trim( newVal ).length ) {
			$folderNameEl.html( newVal );
			toggleRenameForm.call( this, e, true );

			$.ajax({
				  type    : "POST"
				, url     : url
				, data    : $form.serialize()
				, success : function( data ) { processSaveResponse( data ); }
				, error   : function() { processSaveResponse( {} ); }
			});
		}
	};

	processSaveResponse = function( data ){
		if ( data.success ) {
			$.gritter.add( {
				  title      : i18n.translateResource( "cms:assetmanager.notifications.folder.renamed.success.title" )
				, text       : i18n.translateResource( "cms:assetmanager.notifications.folder.renamed.success.description" )
				, class_name : "gritter-success"
			} );
		} else {
			$folderNameEl.html( originalVal );
			if ( data.message && data.title ) {
				$.gritter.add( {
					  title      : data.title
					, text       : data.message
					, class_name : "gritter-error"
				} );
			} else {
				$.gritter.add( {
					  title      : i18n.translateResource( "cms:assetmanager.notifications.folder.renamed.error.title" )
					, text       : i18n.translateResource( "cms:assetmanager.notifications.folder.renamed.error.description" )
					, class_name : "gritter-error"
				} );
			}
		}
	};

	setupEventListeners();

} )( presideJQuery );