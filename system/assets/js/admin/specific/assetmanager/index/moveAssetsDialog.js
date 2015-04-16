( function( $ ){

	var MoveAssetsDialog, getSelectedAssets;

	MoveAssetsDialog = function( $dialogContainer, assets, fromFolder, title  ){
		this.$dialogContainer = $dialogContainer;
		this.assets           = assets;
		this.fromFolder       = fromFolder;

		this.setupModalConfig( title );
	};

	MoveAssetsDialog.prototype.open = function(){
		var modal  = presideBootbox.dialog( this.modalConfig )
		  , dialog = this;

		modal.on( "shown.bs.modal", function(){
			$( modal ).find( '.dialog-container' ).append( dialog.$dialogContainer );

			dialog.$dialogContainer.removeClass( 'hide' );
			dialog.$dialogContainer.find( 'input[name="assets"]' ).val( dialog.assets );
			dialog.$dialogContainer.find( 'input[name="fromFolder"]' ).val( dialog.fromFolder );
		} );

		modal.modal( "show" );
	};

	MoveAssetsDialog.prototype.setupModalConfig = function( title ){
		var dialog = this;

		this.modalConfig = {
			  title     : title
			, message   : '<div class="dialog-container"></div>'
			, className : ""
			, show      : false
			, buttons   : {}
		}
		this.modalConfig.buttons.cancel = {
			label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" ),
			className : "btn-default",
			callback  : function(){ dialog.onCancel() }
		};
		this.modalConfig.buttons.ok = {
			label     : '<i class="fa fa-check"></i> ' + i18n.translateResource( "cms:ok.btn" ),
			className : "btn-primary",
			callback  : function(){ dialog.onOk() }
		};
	}

	MoveAssetsDialog.prototype.onCancel = function(){ this.gracefullyShutdown(); };
	MoveAssetsDialog.prototype.onOk     = function(){
		$('body').presideLoadingSheen( true );
		this.$dialogContainer.find( 'form' ).first().submit();
	};

	MoveAssetsDialog.prototype.gracefullyShutdown = function(){
		this.$dialogContainer.addClass( "hide" );
		$( "body" ).append( this.$dialogContainer );
	};

	$( "body" ).on( "click", 'a[data-toggle="move-assets-dialog"]', function( e ){
		e.preventDefault();

		var $link            = $( this )
		  , $dialogContainer = $( this.hash )
		  , assets           = $link.data( "assetId" )
		  , fromFolder       = $link.data( "folderId" )
		  , title            = $link.data( "dialogTitle" )
		  , dialog           = new MoveAssetsDialog( $dialogContainer, assets, fromFolder, title );

		dialog.open();

	} );

	$( "body" ).on( "click", 'button[data-toggle="move-assets-dialog"]', function( e ){
		e.preventDefault();

		var $button          = $( this )
		  , $dialogContainer = $( '#' + $button.data( "target" ) )
		  , assets           = getSelectedAssets( $button.closest( "form" ) )
		  , fromFolder       = ""
		  , title            = $button.data( "dialogTitle" )
		  , dialog           = new MoveAssetsDialog( $dialogContainer, assets, fromFolder, title );

		dialog.open();

	} );

	getSelectedAssets = function( $form ){
		var assets = [];

		$form.find( "[name='id']:checked" ).each( function(){
			assets.push( $(this).val() );
		} );

		return assets.join( "," );
	};

} )( presideJQuery );