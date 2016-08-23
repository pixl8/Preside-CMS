( function( $ ){

	var expressionLib = cfrequest.rulesEngineExpressions || {};

	$.fn.rulesEngineConditionBuilder = function(){
		return this.each( function(){
			var $formControl      = $( this )
			  , $builderContainer = $formControl.next( "div.rules-engine-condition-builder" )
			  , $searchInput      = $builderContainer.find( ".rules-engine-condition-builder-expression-search" )
			  , $expressionList   = $builderContainer.find( ".rules-engine-condition-builder-expressions-list" )
			  , $conditionPanel   = $builderContainer.find( ".rules-engine-condition-builder-condition-pane" )
			  , $ruleList         = $builderContainer.find( ".rules-engine-condition-builder-rule-list" )
			  , $expressions      = $expressionList.find( "> li" )
			  , tabIndex          = $formControl.attr( "tabindex" )
			  , savedCondition    = $formControl.val()
			  , expressions       = expressionLib[ $formControl.attr( "id" ) ] || []
			  , performSearch
			  , initializeBuilder
			  , prepareSearchEngine
			  , prepareDragAndDrop
			  , addExpression
			  , sortableStop;

			initializeBuilder = function() {
				$formControl.removeAttr( "tabindex" ).addClass( "hide" );
				$builderContainer.removeClass( "hide" );
				$searchInput.on( "keyup", performSearch );

				prepareSearchEngine();
				prepareDragAndDrop();
			};

			prepareSearchEngine = function(){
				$expressions.each( function(){
					var $expression = $( this );

					$expression.data( "originalText", $expression.text() )
				} );
			};

			performSearch = function() {
				var query = $searchInput.val();

				$expressions.each( function(){
					var $expression    = $( this )
					  , expressionText = $expression.data( "originalText" );

					if ( !query.length ) {
						$expression.removeClass( "hide" );
						$expression.html( expressionText );
					} else {
						if ( expressionText.toLowerCase().includes( query.toLowerCase() ) ) {
							$expression.removeClass( "hide" );
							$expression.html(
								expressionText.replace( new RegExp( query, "gi" ), function( match ){ return "<b>" + match + "</b>" } )
							);
						} else {
							$expression.addClass( "hide" );
						}
					}
				} );

			};

			prepareDragAndDrop = function() {
				$expressions.draggable( { helper : "clone" } );
				$conditionPanel.droppable({
					  accept     : $expressions
		        	, drop       : addExpression
		        	, hoverClass : "ui-droppable-hover"
				});
			};

			addExpression = function( event, ui ){
				var $expression = ui.draggable.clone();
				alert( $expression.data( "id" ) );
			};

			sortableStop = function(){

			};

			initializeBuilder();
		} );
	};

	$( "textarea.rules-engine-condition-builder" ).rulesEngineConditionBuilder();

} )( presideJQuery );