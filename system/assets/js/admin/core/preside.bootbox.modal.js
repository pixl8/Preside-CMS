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
			modalConfig = initModalConfig( $modalLink );
		}

		openModal( modalConfig );
	}

	openModal = function( config ){
		presideBootbox.dialog( config );
	};

	initModalConfig = function( $modalLink ){
		var buttonList = ( $modalLink.data( "buttons" ) || "ok cancel" ).split( " " )
		  , $target    = $( $modalLink.get(0).hash )
		  , config, i;

		config = {
			  title     : $modalLink.data( "title" ) || $modalLink.attr( "title" )
			, message   : $target.html()
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

		return config;
	};

	btnCallBack = function( $modalLink, action ){
		$modalLink.trigger( "bootboxModal" + action );
	};

	registerEventHandlers();

} )( presideJQuery );