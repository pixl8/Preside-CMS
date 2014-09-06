( function( $ ){

	var UberSelectWithQuickAdd = (function() {
		function UberSelectWithQuickAdd( $originalInput ) {
			this.$originalInput = $originalInput;

			this.setupUberSelect();
			this.setupQuickAdd();
		}

		UberSelectWithQuickAdd.prototype.setupUberSelect = function(){
			this.$originalInput.uberSelect({
				  allow_single_deselect  : true
				, inherit_select_classes : true
			});
			this.$uberSelect = this.$originalInput.next();
			this.uberSelect = this.$originalInput.data( "uberSelect" );
		};

		UberSelectWithQuickAdd.prototype.setupQuickAdd = function(){
			var iframeSrc       = this.$originalInput.data( "quickAddUrl" )
			  , modalTitle      = this.$originalInput.data( "quickAddModalTitle" )
			  , iframeId        = this.$originalInput.attr('id') + "_quickadd_frame"
			  , onLoadCallback  = "cb" + iframeId
			  , uberSelectWithQuickAdd = this;

			window[ onLoadCallback ] = function( iframe ){
				iframe.uberSelectWithQuickAdd = uberSelectWithQuickAdd;
			};
			this.$quickAddIframeContainer = $( '<div id="' + iframeId + '" style="display:none;"><iframe class="quick-add-iframe" src="' + iframeSrc + '" width="900" height="250" frameBorder="0" onload="' + onLoadCallback + '( this.contentWindow )"></iframe></div>' );
			this.$quickAddButton = $( '<a class="btn btn-default quick-add-btn" href="#' + iframeId + '" title="' + modalTitle + '"><i class="fa fa-plus"></i></a>' );
			if ( this.$originalInput.attr( "tabindex" ) ) {
				this.$quickAddButton.attr( "tabindex", this.$originalInput.attr( "tabindex" ) );
			}


			this.$uberSelect.after( this.$quickAddIframeContainer );
			this.$uberSelect.after( this.$quickAddButton );

			this.$quickAddButton.data( 'modalClass', 'quick-add-modal' );

			this.$quickAddButton.presideBootboxModal({
				buttons : {
					cancel : {
						  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
						, className : "btn-default"
					},
					add : {
						  label     : '<i class="fa fa-plus"></i> ' + i18n.translateResource( "cms:add.btn" )
						, className : "btn-primary"
						, callback  : function(){ return uberSelectWithQuickAdd.processAddRecord(); }
					}
				},
				onShow : function( modal ){
					var uploadIFrame = uberSelectWithQuickAdd.getQuickAddIFrame();

					if ( typeof uploadIFrame.quickAdd !== "undefined" ) {
						uploadIFrame.quickAdd.focusForm();

						return false;
					}

					modal.on('hidden.bs.modal', function (e) {
		  				modal.remove();
					} );
				}
			});
		};

		UberSelectWithQuickAdd.prototype.addRecordToControl = function( recordId ){
			this.uberSelect.select( recordId );
		};

		UberSelectWithQuickAdd.prototype.closeQuickAddDialog = function(){
			var modal = this.$quickAddButton.data( 'modal' );

			modal.modal( 'hide' );

			this.uberSelect.search_field.focus();
		};

		UberSelectWithQuickAdd.prototype.processAddRecord = function(){
			var uploadIFrame = this.getQuickAddIFrame();

			if ( typeof uploadIFrame.quickAdd !== "undefined" ) {
				uploadIFrame.quickAdd.submitForm();

				return false;
			}

			return true;
		};

		UberSelectWithQuickAdd.prototype.quickAddFinished = function(){
			var modal = this.$quickAddButton.data( 'modal' );

			modal.on('hidden.bs.modal', function (e) {
  				modal.remove();
			} );
			modal.modal( 'hide' );
		};

		UberSelectWithQuickAdd.prototype.getQuickAddIFrame = function(){
			var $iframe = $( '.modal-dialog iframe.quick-add-iframe' );
			if ( $iframe.length ) {
				return $iframe.get(0).contentWindow;
			}

			return {};
		};

		return UberSelectWithQuickAdd;
	})();


	$.fn.uberSelectWithQuickAdd = function(){
		return this.each( function(){
			new UberSelectWithQuickAdd( $(this) );
		} );
	};

} )( presideJQuery );