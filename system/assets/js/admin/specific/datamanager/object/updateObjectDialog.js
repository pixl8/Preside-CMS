( function( $ ){

	var MoveObjectDialog, getSelectedObjects;

	MoveObjectDialog = function( $dialogContainer, id, title  ){
		this.$dialogContainer = $dialogContainer;
		this.id               = id;
		this.setupModalConfig( title );
	};

	MoveObjectDialog.prototype.open = function(){
		var modal  = presideBootbox.dialog( this.modalConfig )
		  , dialog = this;

		modal.on( "shown.bs.modal", function(){
			$( modal ).find( '.dialog-container' ).append( dialog.$dialogContainer );
			dialog.$dialogContainer.removeClass( 'hide' );
			dialog.$dialogContainer.find( 'input[name="id"]' ).val( dialog.id );
		} );

		modal.modal( "show" );
	};

	MoveObjectDialog.prototype.setupModalConfig = function( title ){
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

	MoveObjectDialog.prototype.onCancel = function(){ this.gracefullyShutdown(); };
	MoveObjectDialog.prototype.onOk     = function(){
		$('body').presideLoadingSheen( true );
		this.$dialogContainer.find( 'form' ).first().submit();
	};

	MoveObjectDialog.prototype.gracefullyShutdown = function(){
		this.$dialogContainer.addClass( "hide" );
		$( "body" ).append( this.$dialogContainer );
	};
	

	$( "body" ).on( "click", 'button[data-toggle="update-object-dialog"]', function( e ){
		e.preventDefault();

		var $button          = $( this )
		  , $dialogContainer = $( '#' + $button.data( "target" ) )
		  , id               = getSelectedObjects( $button.closest( "form" ) )
		  , title            = $button.data( "dialogTitle" )
		  , dialog           = new MoveObjectDialog( $dialogContainer, id, title );

		dialog.open();

	} );

	getSelectedObjects = function( $form ){
		var assets = [];

		$form.find( "[name='id']:checked" ).each( function(){
			assets.push( $(this).val() );
		} );

		return assets.join( "," );
	};

} )( presideJQuery );