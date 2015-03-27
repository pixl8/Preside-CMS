( function( $ ){

	var idGenerator = function(){
		return 'iframexxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
			return v.toString(16);
		} );
	};

	window.PresideIframeModal = ( function(){
		function PresideIframeModal( iframeUrl, width, height, callbacks, modalOptions ) {
			this.callbacks    = callbacks;
			this.iframeUrl    = iframeUrl;
			this.width        = width;
			this.height       = height;
			this.modalOptions = modalOptions;
		};

		PresideIframeModal.prototype.setupIframe = function(){
			var iframeId       = this.iframeId = idGenerator()
			  , onLoadCallback = "cb" + iframeId
			  , callbacks      = this.callbacks
			  , iframeModal    = this;


			this.$iframeContainer = $( '<div style="display:none;"><iframe id="' + iframeId + '" src="' + this.iframeUrl + '" width="' + this.width + '" height="' + this.height + '" frameBorder="0" onload="' + onLoadCallback + '( this.contentWindow )"></iframe></div>' );
			this.registerOnLoadCallback( onLoadCallback, function( iframe ){
				iframe.parentPresideBootbox = iframeModal.getBootbox();

				if ( typeof callbacks.onLoad !== "undefined" ) {
					callbacks.onLoad( iframe );
				}
			} );
		};

		PresideIframeModal.prototype.registerOnLoadCallback = function( id, callBack ){
			var target = typeof parentPresideBootbox == "undefined" ? window : ( window.parent || window );

			target[ id ] = callBack;
		};

		PresideIframeModal.prototype.setupModalOptions = function(){
			var buttonList = this.modalOptions.buttonList || []
			  , presideIframeModal = this
			  , i;

			this.modalOptions.show    = false;
			this.modalOptions.message = this.$iframeContainer.html();
			this.modalOptions.buttons = this.modalOptions.buttons || {};

			if ( $.isEmptyObject( this.modalOptions.buttons ) ) {
				for( i=0; i < buttonList.length; i++ ){
					if ( buttonList[i] === "cancel" ) {
						this.modalOptions.buttons.cancel = {
							label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" ),
							className : "btn-default",
							callback  : function(){ return presideIframeModal.btnCallBack( "cancel" ); }
						};
					} else if ( buttonList[i] === "ok" ) {
						this.modalOptions.buttons.ok = {
							label     : '<i class="fa fa-check"></i> ' + i18n.translateResource( "cms:ok.btn" ),
							className : "btn-primary",
							callback  : function(){ return presideIframeModal.btnCallBack( "ok" ); }
						};
					}
				}
			}
		}

		PresideIframeModal.prototype.btnCallBack = function( action ){
			if ( typeof this.callbacks[ "on" + action ] !== "undefined" ) {
				return this.callbacks[ "on" + action ]();
			}
		};

		PresideIframeModal.prototype.open = function(){
			this.setupIframe();
			this.setupModalOptions();

			var bootbox   = this.getBootbox()
			  , modal     = this.modal = bootbox.dialog( this.modalOptions )
			  , callbacks = this.callbacks
			  , getIframe = this.getIframe;

			if ( typeof callbacks.onShow === "function" ) {
				modal.on( "shown.bs.modal", function(){
					modal.off( "shown.bs.modal" );
					callbacks.onShow( modal, getIframe() );
				} );
			}

			modal.modal( "show" );
		};

		PresideIframeModal.prototype.close = function(){
			var modal = this.modal;

			modal.on('hidden.bs.modal', function (e) {
  				modal.remove();
			} );
			modal.modal( 'hide' );
		};

		PresideIframeModal.prototype.getIframe = function(){
			var $iframe = $( "#"  + this.iframeId );

			if ( $iframe.length ) {
				return $iframe.get(0).contentWindow;
			}
		};

		PresideIframeModal.prototype.getModal = function(){
			return this.modal;
		};

		PresideIframeModal.prototype.getBootbox = function(){
			return typeof parentPresideBootbox == "undefined" ? presideBootbox : parentPresideBootbox;
		};

		return PresideIframeModal;
	} )();

} )( presideJQuery );