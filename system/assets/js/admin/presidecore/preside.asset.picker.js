( function( $ ){

	var UberAssetSelect = (function() {
		function UberAssetSelect( $originalInput ) {
			this.$originalInput = $originalInput;

			this.setupUberSelect();
			this.setupUploader();
			this.setupBrowser();
		}

		UberAssetSelect.prototype.setupUberSelect = function(){
			this.$originalInput.uberSelect({
				  allow_single_deselect  : true
				, inherit_select_classes : true
			});
			this.$uberSelect = this.$originalInput.next();
			this.uberSelect = this.$originalInput.data( "uberSelect" );
		};

		UberAssetSelect.prototype.setupBrowser = function(){
			var iframeSrc       = this.$originalInput.data( "browserUrl" )
			  , modalTitle      = this.$originalInput.data( "modalTitle" )
			  , uberAssetSelect = this
			  , modalOptions    = {
					title      : modalTitle,
					className  : "full-screen-dialog",
					buttonList : [ "ok", "cancel" ]
				}
			  , callbacks = {
			  		onLoad : function( iframe ) {
						uberAssetSelect.pickerIframe = iframe;
					},
			  		onok : function(){ return uberAssetSelect.processBrowserOk(); }
				};

			this.browserIframeModal = new PresideIframeModal( iframeSrc, "100%", "100%", callbacks, modalOptions );

			this.$browserButton = $( '<a class="btn btn-default" href="#"><i class="fa fa-ellipsis-h"></i></a>' );
			this.$uberSelect.after( this.$browserButton );

			this.$browserButton.on( 'click', function( e ){
				e.preventDefault();
				uberAssetSelect.browserIframeModal.open();
			} );
		};

		UberAssetSelect.prototype.setupUploader = function(){
			var iframeSrc       = this.$originalInput.data( "uploaderUrl" )
			  , modalTitle      = this.$originalInput.data( "uploaderModalTitle" )
			  , uberAssetSelect = this
			  , modalOptions    = {
					title      : modalTitle,
					className  : "full-screen-dialog",
					buttons : {
						cancel : {
							  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
							, className : "btn-default"
						},
						ok : {
							  label     : '<i class="fa fa-arrow-circle-o-right"></i> ' + i18n.translateResource( "cms:ok.btn" )
							, className : "btn-primary ok-button"
							, callback  : function(){ return uberAssetSelect.processUploadOk(); }
						}
					}
				}
			  , callbacks = {
			  		onLoad : function( iframe ) {
			  			iframe.uberAssetSelect = uberAssetSelect;
						uberAssetSelect.uploadIframe = iframe;
						$( uberAssetSelect.uploadIframeModal.modal ).find( ".ok-button" ).prop( "disabled", true );
					}
			    };

			this.uploadIframeModal = new PresideIframeModal( iframeSrc, "100%", "100%", callbacks, modalOptions );

			this.$uploaderButton = $( '<a class="btn btn-default upload-btn" href="#"><i class="fa fa-cloud-upload"></i></a>' );
			this.$uploaderButton.on( "click", function( e ){
				e.preventDefault();
				uberAssetSelect.uploadIframeModal.open();
			} );
			this.$uberSelect.after( this.$uploaderButton );
		};

		UberAssetSelect.prototype.processBrowserOk = function(){
			var iFramePicker = this.getPickerIframe();

			if ( typeof iFramePicker !== "undefined" ) {
				var selectedAssets = iFramePicker.getSelected()
				  , i=0, len = selectedAssets.length;

				for( ; i<len; i++ ){
					this.uberSelect.select( selectedAssets[i] );
				}
			}

			return true;
		};

		UberAssetSelect.prototype.processUploadOk = function(){
			var uploadIframe = this.getUploadIframe()
			  , selectedAssets = uploadIframe.assetUploader.getUploaded()
			  , i=0, len = selectedAssets.length;


			if ( len === 0 ) {
				alert( "Warning, no assets uploaded..." );

			}
			for( ; i<len; i++ ){
				this.uberSelect.select( selectedAssets[i] );
			}

			this.uploadIframeModal.close();
		};

		UberAssetSelect.prototype.getPickerIframe = function(){
			return this.pickerIframe.assetBrowser;
		};

		UberAssetSelect.prototype.getUploadIframe = function(){
			return this.uploadIframe;
		};

		return UberAssetSelect;
	})();


	$.fn.uberAssetSelect = function(){
		return this.each( function(){
			new UberAssetSelect( $(this) );
		} );
	};

} )( presideJQuery );