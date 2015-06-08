( function( $ ){

	$.fn.presideBootboxModal = function( modalOptions ){
		return this.each( function(){
			var $modalLink = $( this )
			  , openModal, registerEventHandlers, launchHandler, btnCallBack, initModalConfig;

			launchHandler = function( e ){
				var modalConfig = $modalLink.data( "bootboxModalConfig" );

				e.preventDefault();

				if ( typeof modalConfig === "undefined" ) {
					initModalConfig( function( modalConfig ){
						openModal( modalConfig );
					} );
				} else {
					openModal( modalConfig );
				}
			}

			openModal = function( config ){
				var modal = presideBootbox.dialog( config );
				$modalLink.data( 'modal', modal );
				if ( typeof modalOptions === "object" && typeof modalOptions.onShow === "function" ) {
					modal.on( "shown.bs.modal", function(){
						modal.off( "shown.bs.modal" );
						modalOptions.onShow( modal );
						$( ".modal-backdrop" ).addClass( "presidecms" );
					} );
				}

				modal.modal( "show" );
			};

			initModalConfig = function( callback ){
				var buttonList = ( $modalLink.data( "buttons" ) || "ok cancel" ).split( " " )
				  , config, i, setupConfig;

				setupConfig = function( content ){
					config = $.extend( {
						  title     : $modalLink.data( "title" ) || $modalLink.attr( "title" )
						, message   : content
						, className : $modalLink.data( "modalClass" )
						, buttons   : {}
						, show      : false
					}, modalOptions );

					if ( $.isEmptyObject( config.buttons ) ) {
						for( i=0; i < buttonList.length; i++ ){
							if ( buttonList[i] === "cancel" ) {
								config.buttons.cancel = {
									label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" ),
									className : "btn-default",
									callback  : function(){ return btnCallBack( $modalLink, "cancel" ); }
								};
							} else if ( buttonList[i] === "ok" ) {
								config.buttons.ok = {
									label     : '<i class="fa fa-check"></i> ' + i18n.translateResource( "cms:ok.btn" ),
									className : "btn-primary",
									callback  : function(){ return btnCallBack( $modalLink, "ok" ); }
								};
							}
						}
					}

					$modalLink.data( "bootboxModalConfig", config );

					callback( config );
				};

				if ( $modalLink.get(0).hash.length ) {
					setupConfig( $( $modalLink.get(0).hash ).html() );
				} else {
					$.ajax( {
						  method  : "GET"
						, url     : $modalLink.attr( 'href' )
						, cache   : false
						, success : function( content ){ setupConfig( content ); }
					} );
				}


			};

			btnCallBack = function( $modalLink, action ){
				return $modalLink.triggerHandler( "bootboxModal" + action );
			};

			$modalLink.on( "click", launchHandler );
			$modalLink.data( "presideBootboxModal", true );
		} );
	};

	$( 'body' ).on( "click", '[data-toggle="bootbox-modal"]', function( e ){
		e.preventDefault();

		var $link = $( this );

		if ( !$link.data( "presideBootboxModal" ) ) {
			$link.presideBootboxModal( {} ).click();
		}
	} );
} )( presideJQuery );