( function( $ ){

	var openModal, registerEventHandlers, launchHandler, btnCallBack;

	registerEventHandlers = function(){
		$( "body" ).on( "click", '[data-toggle="bootbox-modal"]', launchHandler );
	};

	launchHandler = function( e ){
		var $modalLink  = $( this )
		  , modalConfig = $modalLink.data( "bootboxModalConfig" );

		e.preventDefault();

		if ( typeof modalConfig === "undefined" ) {
			initModalConfig( $modalLink, function( modalConfig ){
				openModal( modalConfig );
			} );
		} else {
			openModal( modalConfig );
		}
	}

	openModal = function( config ){
		presideBootbox.dialog( config );
	};

	initModalConfig = function( $modalLink, callback ){
		var buttonList = ( $modalLink.data( "buttons" ) || "ok cancel" ).split( " " )
		  , config, i, setupConfig;

		setupConfig = function( content ){
			config = {
				  title     : $modalLink.data( "title" ) || $modalLink.attr( "title" )
				, message   : content
				, className : $modalLink.data( "modalClass" )
				, buttons   : {}
			};

			for( i=0; i < buttonList.length; i++ ){
				if ( buttonList[i] === "cancel" ) {
					config.buttons.cancel = {
						label     : i18n.translateResource( "cms:cancel.btn" ),
						className : "btn-default",
						callback  : function(){ btnCallBack( $modalLink, "cancel" ); }
					};
				} else if ( buttonList[i] === "ok" ) {
					config.buttons.ok = {
						label     : i18n.translateResource( "cms:ok.btn" ),
						className : "btn-primary",
						callback  : function(){ btnCallBack( $modalLink, "ok" ); }
					};
				}
			}

			$modalLink.data( "bootboxModalConfig", config );

			callback( config );
		};

		if ( $modalLink.get(0).hash.length ) {
			setupConfig( $( modalLink.get(0).hash ).html() );
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
		$modalLink.trigger( "bootboxModal" + action );
	};

	registerEventHandlers();

} )( presideJQuery );