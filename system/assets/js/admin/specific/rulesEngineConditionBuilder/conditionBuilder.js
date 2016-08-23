( function( $ ){

	var expressionLib = cfrequest.rulesEngineExpressions || {};
	var RulesEngineCondition = (function() {
		function RulesEngineCondition( $formControl ) {
			this.$formControl = $formControl;
			this.model = this.deserialize( this.$formControl.val() );

			this.render();
		}

		RulesEngineCondition.prototype.persistToHiddenField = function() {
			this.$formControl.val( this.serialize() );
		};

		RulesEngineCondition.prototype.serialize = function() {
			return JSON.stringify( this.model );
		};

		RulesEngineCondition.prototype.deserialize = function( initialConditionValue ) {
			if ( this.isValidSerializedCondition( initialConditionValue ) ) {
				try {
					return JSON.parse( initialConditionValue );
				} catch( e ) {}
			}

			return [];
		};

		RulesEngineCondition.prototype.isValidSerializedCondition = function( serializedCondition ) {
			if ( typeof serializedCondition !== "string" ) {
				return false;
			}

			if ( $.trim( serializedCondition ).length === 0 ) {
				return false;
			}

			// TODO: ajax call to validate the json string
			return true;
		};

		RulesEngineCondition.prototype.render = function() {
			console.log( "TODO: render stuff" );
		};

		RulesEngineCondition.prototype.addExpression = function( expressionId ) {
			console.log( "TODO: addExpression() logic. Here we were passed expression ID: " + expressionId );
			this.persistToHiddenField();
			this.render();
		};

		RulesEngineCondition.prototype.removeExpression = function() {
			console.log( "TODO: removeExpression() logic" );
			this.persistToHiddenField();
			this.render();
		};

		RulesEngineCondition.prototype.saveExpressionFieldValue = function() {
			console.log( "TODO: saveExpressionFieldValue() logic" );
			this.persistToHiddenField();
			this.render();
		};


		return RulesEngineCondition;
	})();

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
			  , $hiddenControl
			  , condition
			  , performSearch
			  , initializeBuilder
			  , prepareSearchEngine
			  , prepareDragAndDrop
			  , addExpression
			  , sortableStop;

			initializeBuilder = function() {
				var id       = $formControl.attr( "id" )
				  , name     = $formControl.attr( "name" )
				  , tabIndex = $formControl.attr( "tabindex" )
				  , val      = $formControl.val();


				$builderContainer.removeClass( "hide" );
				$searchInput.on( "keyup", performSearch );

				$hiddenControl = $( '<input type="hidden">' );
				$hiddenControl.val( val );
				$hiddenControl.attr( "name", name );
				$formControl.after( $hiddenControl );
				$formControl.remove();
				$hiddenControl.attr( "id", id );

				condition = new RulesEngineCondition( $hiddenControl );

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
				condition.addExpression( $expression.data( "id" ) );
			};

			sortableStop = function(){

			};

			initializeBuilder();
		} );
	};

	$( "textarea.rules-engine-condition-builder" ).rulesEngineConditionBuilder();

} )( presideJQuery );