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
					className  : "uber-browser-dialog",
					buttonList : [ "ok", "cancel" ]
				}
			  , callbacks = {
			  		onLoad : function( iframe ) {
						uberAssetSelect.pickerIframe = iframe;
					},
			  		onok : function(){ return uberAssetSelect.processBrowserOk(); }
			    };

			this.browserIframeModal = new PresideIframeModal( iframeSrc, 900, 400, callbacks, modalOptions );

			this.$browserButton = $( '<a class="btn btn-default" href="#"><i class="fa fa-ellipsis-h"></i></a>' );
			this.$uberSelect.after( this.$browserIframeContainer );
			this.$uberSelect.after( this.$browserButton );

			this.$browserButton.on( 'click', function( e ){
				e.preventDefault();
				uberAssetSelect.browserIframeModal.open();
			} );
		};

		UberAssetSelect.prototype.setupUploader = function(){
			var iframeSrc       = this.$originalInput.data( "uploaderUrl" )
			  , modalTitle      = this.$originalInput.data( "uploaderModalTitle" )
			  , iframeId        = this.$originalInput.attr('id') + "_uploader_frame"
			  , onLoadCallback  = "cb" + iframeId
			  , uberAssetSelect = this;

			window[ onLoadCallback ] = function( iframe ){
				iframe.uberAssetSelect = uberAssetSelect;
				if ( typeof iframe.assetUploader !== "undefined" ) {
					iframe.assetUploader.checkLastStep();
				}
			};
			this.$uploaderIframeContainer = $( '<div id="' + iframeId + '" style="display:none;"><iframe class="upload-iframe" src="' + iframeSrc + '" width="800" height="320" frameBorder="0" onload="' + onLoadCallback + '( this.contentWindow )"></iframe></div>' );
			this.$uploaderButton = $( '<a class="btn btn-default upload-btn" href="#' + iframeId + '" title="' + modalTitle + '"><i class="fa fa-cloud-upload"></i></a>' );

			this.$uberSelect.after( this.$uploaderIframeContainer );
			this.$uberSelect.after( this.$uploaderButton );

			this.$uploaderButton.data( 'modalClass', 'uber-browser-dialog' );

			this.$uploaderButton.presideBootboxModal({
				buttons : {
					cancel : {
						  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
						, className : "btn-default"
					},
					next : {
						  label     : '<i class="fa fa-arrow-circle-o-right"></i> ' + i18n.translateResource( "cms:next.btn" )
						, className : "btn-primary"
						, callback  : function(){ return uberAssetSelect.processUploadNextButton(); }
					}
				}
			});

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

		UberAssetSelect.prototype.processUploadNextButton = function(){
			var uploadIFrame = this.getUploadIframe();

			if ( typeof uploadIFrame.assetUploader !== "undefined" ) {
				$( uploadIFrame ).focus();
				uploadIFrame.assetUploader.nextStep();

				return false;
			}

			return true;
		};

		UberAssetSelect.prototype.uploadStepsFinished = function(){
			var modal = this.$uploaderButton.data( 'modal' )
			  , uploadIFrame = this.getUploadIframe();

			var selectedAssets = uploadIFrame.assetUploader.getUploaded()
			  , i=0, len = selectedAssets.length;

			for( ; i<len; i++ ){
				this.uberSelect.select( selectedAssets[i] );
			}

			modal.on('hidden.bs.modal', function (e) {
  				modal.remove();
			} );
			modal.modal( 'hide' );
		};

		UberAssetSelect.prototype.enteredLastStep = function(){
			var $modal      = this.$uploaderButton.data( 'modal' )
			  , $nextButton = $modal.length && $modal.find( "button[data-bb-handler='next']" );

			if ( $nextButton.length ) {
				$nextButton.html( '<i class="fa fa-check"></i> ' + i18n.translateResource( "cms:done.btn" ) );
			}
		};

		UberAssetSelect.prototype.getPickerIframe = function(){
			return this.pickerIframe.assetBrowser;
		};

		UberAssetSelect.prototype.getUploadIframe = function(){
			var $iframe = $( '.modal-dialog iframe.upload-iframe' );
			if ( $iframe.length ) {
				return $iframe.get(0).contentWindow;
			}

			return {};
		};

		return UberAssetSelect;
	})();


	$.fn.uberAssetSelect = function(){
		return this.each( function(){
			new UberAssetSelect( $(this) );
		} );
	};

} )( presideJQuery );