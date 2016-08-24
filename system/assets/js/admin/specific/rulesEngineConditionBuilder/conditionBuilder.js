( function( $ ){

	var expressionLib        = cfrequest.rulesEngineExpressions || {}
	  , renderFieldEndpoint  = cfrequest.rulesEngineRenderFieldEndpoint || "";

	var RulesEngineCondition = (function() {
		function RulesEngineCondition( $formControl, expressions, $ruleList ) {
			this.$formControl     = $formControl;
			this.$ruleList        = $ruleList;
			this.model            = this.deserialize( this.$formControl.val() );
			this.expressions      = expressions;
			this.fieldRenderCache = {};

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
			var lis, transformExpressionsToHtmlLis, i, rulesEngineCondition=this;

			transformExpressionsToHtmlLis = function( expressions, depth ) {
				var lis        = []
				  , indent     = ( 20 * depth )
				  , liTemplate = '<li style="margin-left:' + indent + 'px"></li>'
				  , $li, i;

				for( i=0; i<expressions.length; i++ ) {
					var isOddRow = i % 2
					  , expression = expressions[i];


					if ( isOddRow ) {
						$li = $( liTemplate );
						$li.html( expression );
						lis.push( $li );
					} else if ( Array.isArray( expression ) ) {
						lis = lis.concat( transformExpressionsToHtmlLis( expression, depth+1 ) );
					} else {
						$li = $( liTemplate );
						$li.html( rulesEngineCondition.renderExpression( expression ) );
						lis.push( $li );
					}
				}

				return lis;
			};

			lis = transformExpressionsToHtmlLis( this.model, 0 );
			this.$ruleList.html( "" );
			for( i=0; i<lis.length; i++ ) {
				this.$ruleList.append( lis[i] );
			}
		};

		RulesEngineCondition.prototype.addExpression = function( expressionId ) {
			var newExpression = this.newExpression( expressionId );

			if ( this.model.length ) {
				this.model.push( "and" );
			}
			this.model.push( newExpression );

			this.persistToHiddenField();
			this.render();
		};

		RulesEngineCondition.prototype.newExpression = function( expressionId ) {
			var expression = this.getExpression( expressionId )
			  , newExpression;

			if ( expression === null ) {
				return {};
			}

			newExpression = {
				  expression : expression.id
				, fields     : {}
			};

			for( fieldName in expression.fields ){
				if ( typeof expression.fields[ fieldName ].default === "undefined" ) {
					newExpression.fields[ fieldName ] = null;
				} else {
					newExpression.fields[ fieldName ] = expression.fields[ fieldName ].default;
				}
			}

			return newExpression;
		};

		RulesEngineCondition.prototype.getExpression = function( expressionId ) {
			var i, expression;

			for( i=this.expressions.length-1; i>=0; i-- ) {
				expression = this.expressions[ i ];
				if ( expression.id.toLowerCase() === expressionId.toLowerCase() ) {
					return expression;
				}
			}

			return;
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

		RulesEngineCondition.prototype.renderExpression = function( expression ) {
			var definition = this.getExpression( expression.expression )
			  , text       = definition.text || ""
			  , $expression = $( "<span></span>" )
			  , fieldName, fieldValue, fieldPatternRegex, fieldDefinition, $field;

			if ( typeof definition.id === "undefined" ) {
				return "";
			}

			for( fieldName in expression.fields ) {
				fieldPatternRegex = new RegExp( "\{" + fieldName + "\}", "gi" );
				text = text.replace( fieldPatternRegex, '<span data-field-name="' + fieldName + '"></span>' );
			}

			$expression.html( text );

			for( fieldName in expression.fields ) {
				fieldValue      = expression.fields[ fieldName ];
				$field          = $expression.find( "[data-field-name=" + fieldName + "]" );

				fieldDefinition = definition.fields[ fieldName ] || {};

				this.renderField( fieldName, fieldValue, fieldDefinition, $field );
			}

			return $expression;
		};

		RulesEngineCondition.prototype.renderField = function( fieldName, fieldValue, fieldDefinition, $field ) {
			var cacheKey = JSON.stringify( { fieldName:fieldName, fieldValue:fieldValue, fieldDefinition:fieldDefinition } );

			if ( fieldValue !== null ) {
				$field.addClass( "rules-engine-condition-builder-field-loading" ).html( "&hellip;" );

				if ( !this.fieldRenderCache[ cacheKey ] ) {
					this.fieldRenderCache[ cacheKey ] = $.post( renderFieldEndpoint, $.extend( {}, { fieldValue:fieldValue }, fieldDefinition ) );
				}

				this.fieldRenderCache[ cacheKey ].done( function( response ){
					$field.html( '<a class="rules-engine-condition-builder-field-link">' + response + '</a>' );
				} );
			} else {
				$field.html( '<a class="rules-engine-condition-builder-field-link">' + "[" + fieldDefinition.defaultLabel + "]" + '</a>' );
			}
		}

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

				condition = new RulesEngineCondition( $hiddenControl, expressions, $ruleList );

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