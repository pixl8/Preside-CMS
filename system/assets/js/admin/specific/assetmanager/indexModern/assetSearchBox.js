( function( $ ){

	var $searchBox = $( '#asset-search-box' )
	  , setupTypeahead, setupBloodhound, suggestionTemplate, renderSuggestion, setupTemplates, itemSelectedHandler;

	setupTypeahead = function(){
		setupBloodhound( function( bloodhound ){
			var typeAheadSettings = {
					  hint      : true
					, highlight : true
					, minLength : 1
				}
			  , datasetSettings = {
			  		  source     : bloodhound
			  		, displayKey : 'text'
			  		, templates  : { suggestion : renderSuggestion }
			    }

			$searchBox.typeahead( typeAheadSettings, datasetSettings );
			$searchBox.on( "typeahead:selected", function( e, result ){ itemSelectedHandler( result ); } );
		} );
	};

	setupBloodhound = function( callback ){
		var engine = new Bloodhound( {
			  local          : []
			, prefetch       : $searchBox.data( "prefetchUrl" )
			, remote         : $searchBox.data( "remoteUrl" )
			, datumTokenizer : function(d) { return Bloodhound.tokenizers.whitespace( d.text ); }
		 	, queryTokenizer : Bloodhound.tokenizers.whitespace
		 	, limit          : 100
		 	, dupDetector    : function( remote, local ){ return remote.value == local.value }
		} );

		( engine.initialize() ).done( function(){
			callback( engine.ttAdapter() );
		} );
	};

	renderSuggestion = function( result ) {
		return Mustache.render( suggestionTemplate, result );
	};

	itemSelectedHandler = function( result ) {
		$('body').presideLoadingSheen( true );
		window.location = buildAdminLink( "assetmanager", "editasset", { asset : result.value } );
	};

	setupTemplates = function(){
		suggestionTemplate = '<div class="result-container"><div class="icon-container">{{{icon}}}</div> <div class="folder-and-text"><span class="folder">{{folder}}</span> <span class="title">{{text}}</span></div></div><div class="clearfix"></div>';
	};

	if ( $searchBox.length ) {
		setupTemplates();
		setupTypeahead();
	}

} )( presideJQuery );