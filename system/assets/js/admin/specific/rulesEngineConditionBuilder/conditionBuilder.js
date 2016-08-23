( function( $ ){

	var expressionLib = cfrequest.rulesEngineExpressions || {};

	$.fn.rulesEngineConditionBuilder = function(){
		return this.each( function(){
			var $formControl      = $( this )
			  , $builderContainer = $formControl.next( "div.rules-engine-condition-builder" )
			  , $searchInput      = $builderContainer.find( ".rules-engine-condition-builder-expression-search" )
			  , $expressionList   = $builderContainer.find( ".rules-engine-condition-builder-expressions-list" )
			  , $expressions      = $expressionList.find( "> li" )
			  , tabIndex          = $formControl.attr( "tabindex" )
			  , savedCondition    = $formControl.val()
			  , expressions       = expressionLib[ $formControl.attr( "id" ) ] || []
			  , performSearch, initializeBuilder;

			initializeBuilder = function() {
				$formControl.removeAttr( "tabindex" ).addClass( "hide" );
				$builderContainer.removeClass( "hide" );
				$searchInput.on( "keyup", performSearch );

				$expressions.each( function(){
					var $expression = $( this );

					$expression.data( "originalText", $expression.text() )
				} );
			};

			performSearch = function() {
				var query = $searchInput.val();

				if ( !query.length ) {
					$expressions.removeClass( "hide" );
				} else {
					$expressions.each( function(){
						var $expression    = $( this )
						  , expressionText = $expression.data( "originalText" );

						if ( expressionText.toLowerCase().includes( query.toLowerCase() ) ) {
							$expression.removeClass( "hide" );
							$expression.html(
								expressionText.replace( new RegExp( query, "gi" ), function( match ){ return "<b>" + match + "</b>" } )
							);
						} else {
							$expression.addClass( "hide" );
						}
					} );
				}
			};


			initializeBuilder();
		} );
	};

	$( "textarea.rules-engine-condition-builder" ).rulesEngineConditionBuilder();

} )( presideJQuery );