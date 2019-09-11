( function( $ ){

	var defaultExpressionLib         = cfrequest.rulesEngineExpressions           || {}
	  , defaultRenderFieldEndpoint   = cfrequest.rulesEngineRenderFieldEndpoint   || ""
	  , defaultEditFieldEndpoint     = cfrequest.rulesEngineEditFieldEndpoint     || ""
	  , defaultFilterCountEndpoint   = cfrequest.rulesEngineFilterCountEndpoint   || ""
	  , defaultContextData           = cfrequest.rulesEngineContextData           || {}
	  , defaultPreSavedFilters       = cfrequest.rulesEnginePreSavedFilters       || ""
	  , defaultPreRulesEngineFilters = cfrequest.rulesEnginePreRulesEngineFilters || ""
	  , defaultContext               = cfrequest.rulesEngineContext               || "global";

	var RulesEngineCondition = (function() {
		function RulesEngineCondition(
			  $formControl
			, expressions
			, $ruleList
			, isFilter
			, $filterCount
			, objectName
			, renderFieldEndpoint
			, editFieldEndpoint
			, filterCountEndpoint
			, contextData
			, preSavedFilters
			, preRulesEngineFilters
			, context
		) {
			this.$formControl          = $formControl;
			this.$ruleList             = $ruleList;
			this.model                 = this.deserialize( this.$formControl.val() );
			this.expressions           = expressions;
			this.fieldRenderCache      = {};
			this.selectedIndex         = null;
			this.isFilter              = isFilter;
			this.renderFieldEndpoint   = renderFieldEndpoint;
			this.editFieldEndpoint     = editFieldEndpoint;
			this.filterCountEndpoint   = filterCountEndpoint;
			this.contextData           = contextData;
			this.preSavedFilters       = preSavedFilters;
			this.preRulesEngineFilters = preRulesEngineFilters;
			this.context               = context;

			if ( this.isFilter ) {
				this.$filterCount = $filterCount;
				this.objectName   = objectName;
			}

			this.setupBehaviors();
			this.render();
		}

		RulesEngineCondition.prototype.persistToHiddenField = function() {
			this.$formControl.val( this.serialize() );
			this.notifyChange();
		};

		RulesEngineCondition.prototype.serialize = function() {
			if ( this.model.length ) {
				return JSON.stringify( this.model );
			}

			return "";
		};

		RulesEngineCondition.prototype.deserialize = function( initialConditionValue ) {
			if ( this.isValidSerializedCondition( initialConditionValue ) ) {
				try {
					return JSON.parse( initialConditionValue );
				} catch( e ) {}
			}

			return [];
		};

		RulesEngineCondition.prototype.loadFromStringValue = function( initialConditionValue ) {
			this.model = this.deserialize( initialConditionValue );
			this.persistToHiddenField();
			this.render();
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
			var lis, $selectedLi, transformExpressionsToHtmlLis, i, rulesEngineCondition=this;

			this.updateFilterCount();

			transformExpressionsToHtmlLis = function( expressions, depth, index ) {
				var lis             = []
				  , liTemplate      = '<li class="rules-engine-condition-builder-expression"></li>'
				  , actionsTemplate = '<span class="rules-engine-condition-builder-expression-actions"></span>'
				  , indent          = ( depth * 30 )
				  , $li, $actions, i, liIndex;

				for( i=0; i<expressions.length; i++ ) {
					var isOddRow   = i % 2
					  , expression = expressions[i]
					  , liIndex    = index.concat( [i] );


					if ( isOddRow ) {
						$li = $( liTemplate );
						$li.data( "modelIndex", liIndex );
				  		$li.html( '<span class="rules-engine-condition-builder-expression-text" style="margin-left:' + indent + 'px;"><a class="rules-engine-condition-builder-join-toggle">' + i18n.translateResource( "cms:rulesEngine.join." + expression ) + '</a></span>' )
						$li.addClass( "rules-engine-condition-builder-expression-join" );
						lis.push( $li );
					} else if ( Array.isArray( expression ) ) {
						lis = lis.concat( transformExpressionsToHtmlLis( expression, depth+1, liIndex ) );
					} else {
						$li = $( liTemplate );
						$li.data( "modelIndex", liIndex );
						$li.html( rulesEngineCondition.renderExpression( expression, depth ) );

						$actions = $( actionsTemplate );
						$li.append( $actions );
						if ( i < expressions.length-1 ) {
							$actions.append( '<a class="fa fa-fw fa-arrow-down rules-engine-condition-builder-expression-move-down"></a>' );
						}
						if ( i ) {
							$actions.append( '<a class="fa fa-fw fa-arrow-up rules-engine-condition-builder-expression-move-up"></a>' );
						}
						if ( depth ) {
							$actions.append( '<a class="fa fa-fw fa-arrow-left rules-engine-condition-builder-expression-move-unindent"></a>' );
						}
						if ( i ) {
							$actions.append( '<a class="fa fa-fw fa-arrow-right rules-engine-condition-builder-expression-move-indent"></a>' );
						}
						$actions.append( '<a class="fa fa-fw fa-trash rules-engine-condition-builder-expression-delete"></a>' );

						if ( rulesEngineCondition.selectedIndex !== null && rulesEngineCondition.selectedIndex.join() === liIndex.join() ) {
							$li.addClass( "selected" );
						}

						lis.push( $li );
					}
				}
				return lis;
			};

			lis = transformExpressionsToHtmlLis( this.model, 0, [] );
			this.$ruleList.html( "" );
			for( i=0; i<lis.length; i++ ) {
				this.$ruleList.append( lis[i] );
				if ( lis[i].hasClass( "selected" ) ) {
					$selectedLi = lis[i];
					$selectedLi.removeClass( "selected" );
				}
			}

			if ( $selectedLi ) {
				this.selectExpression( $selectedLi );
			}
		};

		RulesEngineCondition.prototype.notifyChange = function(){
			this.$formControl.trigger( "change" );
		};

		RulesEngineCondition.prototype.updateFilterCount = function() {
			if ( !this.isFilter || !this.$filterCount.length ) { return; }

			var conditionBuilder = this
			  , postData         = this.contextData;

			postData.condition             = this.serialize();
			postData.objectName            = this.objectName;
			postData.preSavedFilters       = this.preSavedFilters;
			postData.preRulesEngineFilters = this.preRulesEngineFilters;

			conditionBuilder.$filterCount.html( '' ).addClass( "loading" );
			$.post(
				  this.filterCountEndpoint
				, postData
				, function( data ){ conditionBuilder.$filterCount.html( data ).removeClass( "loading" ); }
			);
		};

		RulesEngineCondition.prototype.addExpression = function( expressionId ) {
			var newExpression = this.newExpression( expressionId );

			if ( this.model.length ) {
				this.model.push( "and" );
			}
			this.model.push( newExpression );
			this.selectedIndex = [ this.model.length-1 ];

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
				if ( typeof this.contextData[ fieldName ] !== "undefined" ) {
					newExpression.fields[ fieldName ] = this.contextData[ fieldName ];
				} else if ( typeof expression.fields[ fieldName ].default === "undefined" ) {
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

		RulesEngineCondition.prototype.renderExpression = function( expression, depth ) {
			var definition = this.getExpression( expression.expression );

			if ( typeof definition === "undefined" || definition == null ) {
				return '<em class="red"><i class="fa fa-fw fa-exclamation-triangle"></i> ' + i18n.translateResource( "cms:rulesEngine.invalid.expression" ) + '</em>';
			}

			var text       = definition.text || ""
			  , indent     = ( depth * 30 )
			  , $expression = $( '<span class="rules-engine-condition-builder-expression-text" style="margin-left:' + indent + 'px;"></span>' )
			  , fieldName, fieldValue, fieldPatternRegex, fieldDefinition, $field;

			for( fieldName in expression.fields ) {
				fieldPatternRegex = new RegExp( "\{" + fieldName + "\}", "gi" );
				text = text.replace( fieldPatternRegex, '<span class="rules-engine-condition-builder-field" data-field-name="' + fieldName + '"></span>' );
			}

			$expression.html( text );

			for( fieldName in expression.fields ) {
				fieldValue      = expression.fields[ fieldName ];
				$field          = $expression.find( "[data-field-name=" + fieldName + "]" );

				fieldDefinition = definition.fields[ fieldName ] || {};
				$field.data( "fieldDefinition", fieldDefinition );
				$field.data( "fieldValue", fieldValue );

				this.renderField( fieldName, fieldValue, fieldDefinition, $field, expression.fields );
			}

			return $expression;
		};

		RulesEngineCondition.prototype.renderField = function( fieldName, fieldValue, fieldDefinition, $field, fields ) {
			var cacheKey = JSON.stringify( { fieldName:fieldName, fieldValue:fieldValue, fieldDefinition:fieldDefinition } );

			if ( fieldValue !== null ) {
				$field.addClass( "rules-engine-condition-builder-field-loading" ).html( "&hellip;" );

				if ( !this.fieldRenderCache[ cacheKey ] ) {
					this.fieldRenderCache[ cacheKey ] = $.post( this.renderFieldEndpoint, $.extend( {}, this.contextData, fields, { fieldValue:fieldValue }, fieldDefinition ) );
				}

				this.fieldRenderCache[ cacheKey ].done( function( response ){
					$field.html( '<a class="rules-engine-condition-builder-field-link">' + response + '</a>' );
				} );
			} else {
				$field.html( '<a class="rules-engine-condition-builder-field-link">' + fieldDefinition.defaultLabel + '</a>' );
			}

			if ( fieldDefinition.fieldType !== "boolean" ) {
				this.setupFieldEditModal( fieldName, fieldValue, fieldDefinition, $field, fields );
			}
		};

		RulesEngineCondition.prototype.setupFieldEditModal = function( fieldName, fieldValue, fieldDefinition, $field, fields ){
			var rulesEngineCondition = this
			  , iframeUrl            = this.editFieldEndpoint
			  , qsDelim              = ( iframeUrl.search( /\?/ ) == -1 ) ? "?" : "&"
			  , callbacks, modalOptions, iframeModal, fieldValues;

			callbacks = {
				onLoad : function( iframe ) {
					iframe.rulesEngineCondition = rulesEngineCondition;
					iframe.$field = $field;
					iframe.modal  = iframeModal;

					$field.data( "editIframe", iframe );
				},
				onShow : function( modal, iframe ){
					modal.on('hidden.bs.modal', function (e) {
						modal.remove();
					} );
				}
			};

			modalOptions = {
				title     : i18n.translateResource( "cms:rulesEngine.configure.field.modal.title" ),
				className : "full-screen-dialog limited-size",
				buttons   : {
					cancel : {
						  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
						, className : "btn-default"
					},
					ok : {
						  label     : '<i class="fa fa-check"></i> ' + i18n.translateResource( "cms:ok.btn" )
						, className : "btn-primary"
						, callback  : function(){ return rulesEngineCondition.submitFieldDialog( $field ); }
					}
				}
			};


			iframeUrl += qsDelim + $.param( $.extend( {}, fields, { fieldValue:fieldValue, context:this.context }, fieldDefinition ) );
			iframeModal = new PresideIframeModal( iframeUrl, "100%", "100%", callbacks, modalOptions );
			$field.data( "editModal", iframeModal );
		};

		RulesEngineCondition.prototype.saveFieldValue = function( $field, value ){
			var modal           = $field.data( "editIframe" ).modal
			  , $li             = $field.closest( ".rules-engine-condition-builder-expression" )
			  , expressionModel = this.getModelReferenceFromIndex( $li.data( "modelIndex" ) )
			  , fieldName       = $field.data( "fieldName" );

			expressionModel.fields[ fieldName ] = value;
			this.persistToHiddenField();
			this.render();

			modal.close();
		};

		RulesEngineCondition.prototype.submitFieldDialog = function( $field ){
			var editIframe = $field.data( "editIframe" )
			  , savedValue;

			if ( typeof editIframe.rulesEngineDialog !== "undefined" ) {
				editIframe.rulesEngineDialog.submitForm();
				return false;
			}

			return true;
		};

		RulesEngineCondition.prototype.setupBehaviors = function() {
			var rulesEngineCondition = this;

			this.$ruleList.on( "click", ".rules-engine-condition-builder-join-toggle", function( e ){
				e.preventDefault();

				rulesEngineCondition.selectedIndex = null;
				rulesEngineCondition.toggleJoin( $( this ) );
			} );

			this.$ruleList.on( "click", ".rules-engine-condition-builder-expression:not(.rules-engine-condition-builder-expression-join)", function( e ){
				e.preventDefault();

				if ( !$( e.target ).is( "a" ) ) {
					rulesEngineCondition.selectExpression( $( this ) );
				}
			} );

			this.$ruleList.on( "click", ".rules-engine-condition-builder-field-link", function( e ){
				e.preventDefault();
				rulesEngineCondition.selectExpression( $( this ).closest( ".rules-engine-condition-builder-expression" ) );
				rulesEngineCondition.processFieldClick( $( this ) );
			} );

			this.$ruleList.on( "click", ".rules-engine-condition-builder-expression-delete", function( e ){
				e.preventDefault();
				rulesEngineCondition.processDeleteExpressionClick( $( this ) );
			} );

			this.$ruleList.on( "click", ".rules-engine-condition-builder-expression-move-up", function( e ){
				e.preventDefault();
				rulesEngineCondition.processMoveExpressionClick( $( this ), "up" );
			} );

			this.$ruleList.on( "click", ".rules-engine-condition-builder-expression-move-down", function( e ){
				e.preventDefault();
				rulesEngineCondition.processMoveExpressionClick( $( this ), "down" );
			} );

			this.$ruleList.on( "click", ".rules-engine-condition-builder-expression-move-indent", function( e ){
				e.preventDefault();
				rulesEngineCondition.processIndentExpressionClick( $( this ), "indent" );
			} );

			this.$ruleList.on( "click", ".rules-engine-condition-builder-expression-move-unindent", function( e ){
				e.preventDefault();
				rulesEngineCondition.processIndentExpressionClick( $( this ), "unindent" );
			} );
		};

		RulesEngineCondition.prototype.getModelIndexString = function( index ){
			var string = "this.model", i;

			if ( index.length ) {
				string += "[";

				for( i=0; i<index.length; i++ ) {
					string += index[i];
					if ( i < ( index.length-1 ) ) {
						string += '][';
					}
				}

				string += "]";
			}

			return string;
		};

		RulesEngineCondition.prototype.toggleJoin = function( $clickedJoin ) {
			var $li = $clickedJoin.closest( ".rules-engine-condition-builder-expression" )
			  , modelIndexString, currentValue, newValue;

			if ( $li.length ) {
				modelIndexString = this.getModelIndexString( $li.data( "modelIndex" ) );
				currentValue     = eval( modelIndexString );
				newValue         = currentValue === "and" ? "or" : "and";

				eval( modelIndexString + ' = "' + newValue + '"' );

				this.persistToHiddenField();
				this.render();
			}
		};

		RulesEngineCondition.prototype.processFieldClick = function( $clickedFieldLink ) {
			var $field = $clickedFieldLink.closest( ".rules-engine-condition-builder-field" )
			  , $li, fieldDefinition, fieldName, fieldValue, expressionModel;

			if ( $field.length ) {
				$li = $field.closest( ".rules-engine-condition-builder-expression" );
				expressionModel = this.getModelReferenceFromIndex( $li.data( "modelIndex" ) );

				fieldDefinition = $field.data( "fieldDefinition" );
				fieldName       = $field.data( "fieldName" );
				fieldValue      = $field.data( "fieldValue" );
				fieldType       = fieldDefinition.fieldType;

				if ( fieldType === "boolean" ) {
					expressionModel.fields[ fieldName ] = !expressionModel.fields[ fieldName ];
					this.persistToHiddenField();
					this.render();
				} else {
					$.ajax({
						  url      : buildAdminLink( "ajaxhelper.temporarilyStoreData" )
						, method   : "POST"
						, data     : this.contextData
						, complete : function(){
							$field.data( "editModal" ).open();
						 }
					});
				}

			}
		};

		RulesEngineCondition.prototype.processDeleteExpressionClick = function( $clickedLink ) {
			var $li         = $clickedLink.closest( ".rules-engine-condition-builder-expression" )
			  , modelIndex  = $li.data( "modelIndex" );

			this.deleteExpression( modelIndex );
		};

		RulesEngineCondition.prototype.deleteExpression = function( modelIndex ) {
			var listPosition = modelIndex[ modelIndex.length-1 ]
			  , parentIndex, parentList;

			if ( modelIndex.length > 1 ) {
				parentIndex = modelIndex.slice( 0, modelIndex.length-1 );
				parentList  = this.getModelReferenceFromIndex( parentIndex );
			} else {
				parentList = this.model;
			}

			parentList.splice( listPosition, 1 );
			if ( parentList.length ) {
				if ( listPosition === 0 ) {
					parentList.splice( listPosition, 1 );
				} else {
					parentList.splice( listPosition-1, 1 );
				}
			}

			if ( !parentList.length && modelIndex.length > 1 ) {
				this.deleteExpression( parentIndex );
			}

			this.persistToHiddenField();
			this.render();
		};

		RulesEngineCondition.prototype.getModelReferenceFromIndex = function( index ) {
			return eval( this.getModelIndexString( index ) );
		};

		RulesEngineCondition.prototype.selectExpression = function( $li ){
			var selectedClass = "rules-engine-condition-builder-expression-selected"
			  , hasClass      = $li.hasClass( selectedClass );

			this.$ruleList.find( ".rules-engine-condition-builder-expression" ).removeClass( "rules-engine-condition-builder-expression-selected" );

			if ( !hasClass ) {
				$li.addClass( selectedClass );
				this.selectedIndex = $li.data( "modelIndex" );
			}
		};

		RulesEngineCondition.prototype.processMoveExpressionClick = function( $clickedLink, direction ){
			var $li         = $clickedLink.closest( ".rules-engine-condition-builder-expression" )
			  , modelIndex  = $li.data( "modelIndex" );

			this.moveExpression( modelIndex, direction );
		};

		RulesEngineCondition.prototype.moveExpression = function( modelIndex, direction ) {
			var listPosition = modelIndex[ modelIndex.length-1 ]
			  , swapIndex    = direction == "up" ? ( listPosition - 2 ) : ( listPosition + 2 )
			  , parentIndex, parentList, tmp;

			if ( modelIndex.length > 1 ) {
				parentIndex = modelIndex.slice( 0, modelIndex.length-1 );
				parentList  = this.getModelReferenceFromIndex( parentIndex );
			} else {
				parentList = this.model;
			}

			if ( swapIndex >= 0 && swapIndex < parentList.length ) {
				tmp = parentList[ swapIndex ];
				parentList[ swapIndex ] = parentList[ listPosition ];
				parentList[ listPosition ] = tmp;

				this.selectedIndex = modelIndex;
				this.selectedIndex[ this.selectedIndex.length-1 ] = swapIndex;

				this.persistToHiddenField();
				this.render();
			}

		};

		RulesEngineCondition.prototype.processIndentExpressionClick = function( $clickedLink, direction ){
			var $li         = $clickedLink.closest( ".rules-engine-condition-builder-expression" )
			  , modelIndex  = $li.data( "modelIndex" );

			if ( direction == "indent" ) {
				this.indentExpression( modelIndex );
			} else {
				this.unIndentExpression( modelIndex );
			}
		};

		RulesEngineCondition.prototype.indentExpression = function( modelIndex ) {
			var listPosition = modelIndex[ modelIndex.length-1 ]
			  , parentIndex, parentList, tmp, i, parentLength;

			if ( modelIndex.length > 1 ) {
				parentIndex = modelIndex.slice( 0, modelIndex.length-1 );
				parentList  = this.getModelReferenceFromIndex( parentIndex );
			} else {
				parentList = this.model;
			}

			if ( listPosition ) {
				tmp = parentList[ listPosition ];
				parentList[ listPosition ] = [];
				parentList[ listPosition ].push( tmp );
				parentLength = parentList.length;
				for( i=listPosition+1; i<parentLength; i++ ) {
					parentList[ listPosition ].push( parentList[ i ] );
				}
				for( i=parentLength-1; i>listPosition; i-- ) {
					parentList.splice( i, 1 );
				}

				this.selectedIndex = modelIndex;
				this.selectedIndex.push( 0 )

				this.persistToHiddenField();
				this.render();
			}

		};

		RulesEngineCondition.prototype.unIndentExpression = function( modelIndex ) {
			var listPosition       = modelIndex[ modelIndex.length-1 ]
			  , removeFromPosition
			  , insertAtPosition
			  , parentPosition
			  , parentIndex
			  , parentList
			  , grandParentIndex
			  , grandParentList
			  , tmp
			  , i;

			if ( !modelIndex.length ) {
				return;
			}

			parentIndex      = modelIndex.slice( 0, modelIndex.length-1 );
			grandParentIndex = parentIndex.slice( 0, parentIndex.length-1 );
			parentList       = this.getModelReferenceFromIndex( parentIndex );
			grandParentList  = this.getModelReferenceFromIndex( grandParentIndex );

			parentPosition     = parentIndex[ parentIndex.length-1 ];
			parentLength       = parentList.length;
			removeFromPosition = listPosition ? ( listPosition   - 1 ) : 0
			insertAtPosition   = listPosition ? ( parentPosition + 1 ) : parentPosition;

			for( i=removeFromPosition; i<parentLength; i++ ) {
				grandParentList.splice( insertAtPosition, 0, parentList[i] );
				insertAtPosition++;
				if ( !listPosition ) {
					parentPosition++;
				}
			}
			for( i=parentLength-1; i>=removeFromPosition; i-- ) {
				parentList.splice( i, 1 );
			}

			if ( !parentList.length ) {
				grandParentList.splice( parentPosition, 1 );
			}

			this.persistToHiddenField();
			this.render();
		};

		RulesEngineCondition.prototype.clear = function(){
			this.model = [];
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
			  , $filterCount      = $builderContainer.find( ".rules-engine-condition-builder-filter-count-count" )
			  , $expressions      = $expressionList.find( "> li > ul > li.expression" )
			  , $categoryLists    = $expressionList.find( ".category-expressions" )
			  , tabIndex          = $formControl.attr( "tabindex" )
			  , savedCondition    = $formControl.val()
			  , isFilter          = $formControl.data( "isFilter" ) || false
			  , objectName        = $formControl.data( "objectName" )
			  , $hiddenControl
			  , condition
			  , performSearch
			  , initializeBuilder
			  , prepareSearchEngine
			  , prepareDragAndDrop
			  , prepareCategoryAccordion
			  , addExpression
			  , sortableStop
			  , expressions
			  , renderFieldEndpoint
			  , editFieldEndpoint
			  , filterCountEndpoint
			  , contextData
			  , preSavedFilters
			  , preRulesEngineFilters
			  , context;

			initializeBuilder = function() {
				var id          = $formControl.attr( "id" )
				  , name        = $formControl.attr( "name" )
				  , tabIndex    = $formControl.attr( "tabindex" )
				  , val         = $formControl.val()
				  , fieldConfig = cfrequest[ "filter-builder-" + id ] || {};

				expressions           = fieldConfig.rulesEngineExpressions           || ( defaultExpressionLib[ id ] || {} );
				renderFieldEndpoint   = fieldConfig.rulesEngineRenderFieldEndpoint   || defaultRenderFieldEndpoint;
				editFieldEndpoint     = fieldConfig.rulesEngineEditFieldEndpoint     || defaultEditFieldEndpoint;
				filterCountEndpoint   = fieldConfig.rulesEngineFilterCountEndpoint   || defaultFilterCountEndpoint;
				contextData           = fieldConfig.rulesEngineContextData           || defaultContextData;
				preSavedFilters       = fieldConfig.rulesEnginePreSavedFilters       || defaultPreSavedFilters;
				preRulesEngineFilters = fieldConfig.rulesEnginePreRulesEngineFilters || defaultPreRulesEngineFilters;
				context               = fieldConfig.rulesEngineContext               || defaultContext;

				$builderContainer.removeClass( "hide" );
				$searchInput.on( "keyup", performSearch );

				$hiddenControl = $( '<input type="hidden">' );
				$hiddenControl.val( val );
				$hiddenControl.attr( "name", name );
				$formControl.after( $hiddenControl );
				$formControl.remove();
				$hiddenControl.attr( "id", id );

				condition = new RulesEngineCondition(
					  $hiddenControl
					, expressions
					, $ruleList
					, isFilter
					, $filterCount
					, objectName
					, renderFieldEndpoint
					, editFieldEndpoint
					, filterCountEndpoint
					, contextData
					, preSavedFilters
					, preRulesEngineFilters
					, context
				);

				$hiddenControl.data( "conditionBuilder", {
					clear : function(){
						$searchInput.val( "" );
						performSearch();
						condition.clear();
					},
					load : function( value ){
						condition.loadFromStringValue( value );
					}
				} );
				$hiddenControl.trigger( "conditionBuilderInitialized" );

				prepareSearchEngine();
				prepareDragAndDrop();
				prepareCategoryAccordion();
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

				$categoryLists.each( function(){
					var $categoryUl = $( this )
					  , $parentLi   = $categoryUl.parents( "li:first" );

					if ( !query.length ) {
						$parentLi.show();
						if ( $categoryLists.length == 1 ) {
							$parentLi.find( ".fa:first" ).addClass( "fa-minus-square-o" ).removeClass( "fa-plus-square-o" );
							$categoryUl.collapse( "show" );
						} else {
							$parentLi.find( ".fa:first" ).removeClass( "fa-minus-square-o" ).addClass( "fa-plus-square-o" );
							$categoryUl.collapse( "hide" );
						}
					} else if ( $categoryUl.find( "> li:not(.hide)" ).length ) {
						$parentLi.show();
						$parentLi.find( ".fa:first" ).addClass( "fa-minus-square-o" ).removeClass( "fa-plus-square-o" );
						$categoryUl.collapse( "show" );
					} else {
						$parentLi.hide();
						$parentLi.find( ".fa:first" ).removeClass( "fa-minus-square-o" ).addClass( "fa-plus-square-o" );
						$categoryUl.collapse( "hide" );
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

			prepareCategoryAccordion = function(){
				$expressionList.on( "click", ".category-link", function( e ){
					e.preventDefault();
					$( this ).find( ".fa:first" ).toggleClass( "fa-plus-square-o fa-minus-square-o" );
				} );

				if ( $categoryLists.length == 1 ) {
					$categoryLists.each( function(){
						var $categoryUl = $( this )
						  , $parentLi   = $categoryUl.parents( "li:first" );

						$parentLi.show();
						$parentLi.find( ".fa:first" ).addClass( "fa-minus-square-o" ).removeClass( "fa-plus-square-o" );
						$categoryUl.collapse( "show" );
					} );
				}
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