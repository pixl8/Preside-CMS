/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

	property name="confService"        inject="webflowConfigurationService";
	property name="webflowSpecLibrary" inject="webflowSpecLibrary";
	property name="cfflow"             inject="cfflow@cfflow";
	property name="plantUmlService"    inject="plantUmlDiagramService";

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function webflowToSvgDiagram( required string webflowId, boolean collapseSubFlows=false, struct stepStatuses={}, string styles=_getDefaultStyle() ) {
		return plantUmlService.umlToSvgDiagram( webflowToPlantUml( argumentCollection=arguments ) );
	}

	public string function webflowToPlantUml( required string webflowId, boolean collapseSubFlows=false, struct stepStatuses={}, string styles=_getDefaultStyle() ) {
		var umlStateStructure = _calculateUmlStateStructure( webflowId );
		var flowUml           = _renderState( umlStateStructure.structure, webflowId, umlStateStructure.stepQuickLinks, 0, collapseSubFlows, stepStatuses );
		var nl                = Chr( 10 );
		var plantUml          = "@startuml" & nl;

		if ( Len( Trim( arguments.styles ) ) ) {
			plantUml &= arguments.styles & nl;
		}
		plantUml &= flowUml & nl;
		plantUml &= "@enduml";

		return plantUml;
	}

// PRIVATE HELPERS
	private string function _getSubflowForStep( stepId, subflows ) {
		for( var subflow in subflows ) {
			for( var substep in subflows[ subflow ] ) {
				if ( substep == stepid ) {
					return subflow;
				}
			}
		}

		return "";
	}

	private struct function _calculateUmlStateStructure( webflowId ) {
		var webflow           = webflowSpecLibrary.getWebflow( arguments.webflowId );
		var cfflow            = cfflow.getWorkflowLibrary().getWorkflow( webflow.getCfFlowId() );
		var steps             = webflow.getSteps();
		var cfflowSteps       = cfflow.getSteps();
		var subflows          = {};
		var parentChildren    = {};
		var stepLineage       = {};
		var stepQuickLinks    = {};
		var subFlowQuickLinks = {};
		var result = {
			id          = "",
			parent      = "",
			steps       = [],
			subflows    = [],
			transitions = [],
			startSteps  = []
		};
		var _recurseParentChildren = function( parentId ) {
			var children = [];
			for( var subflow in parentChildren[ arguments.parentId ] ?: {} ) {
				if ( Len( Trim( subflow ) ) ) {
					var notFound = children.filter( function( item ){
						return item.id == subflow;
					} ).len() == 0;
					if ( notFound ) {
						children.append( {
							  id = subflow
							, parent = arguments.parentId
							, steps = subflows[ subflow ]
							, subflows =_recurseParentChildren( subflow )
							, transitions = []
						} );

						subFlowQuickLinks[ subflow ] = children.last();
					}
				}
			}

			return children;
		}
		var _getSubflowLineage = function( subflowId ) {
			var lineage = [];

			lineage.append( subflowId );
			var subFlow = subflowQuickLinks[ subflowId ] ?: {};
			if ( Len( Trim( subFlow.parent ?: "" ) ) ) {
				lineage.append( _getSubflowLineage( subFlow.parent ), true );
			}

			return lineage;
		}
		var _downgradeTransitionPath = function( step1, step2 ) {
			var step1Lineage = stepLineage[ arguments.step1 ] ?: [];
			var step2Lineage = stepLineage[ arguments.step2 ] ?: [];

			for( var i=1; i<=step1Lineage.len(); i++ ) {
				var subflow = step1Lineage[ i ];
				var step2Pos = step2Lineage.find( subflow );
				if ( step2Pos ) {
					$SystemOutput( "Downgrading [#step1#->#step2#] to [#(i==1 ? arguments.step1 : "_subflow" & step1Lineage[ i-1 ])#->#( step2Pos==1 ? arguments.step2 : "_subflow" & step2Lineage[ step2Pos-1 ] )#]");
					return {
						subflow = subflow,
						from = i==1 ? arguments.step1 : "_subflow" & step1Lineage[ i-1 ],
						to = step2Pos==1 ? arguments.step2 : "_subflow" & step2Lineage[ step2Pos-1 ]
					};
				}
			}

			return {};
		}
		var _addTransition = function( subflow, from, to ) {
			var transitions = subflowQuickLinks[ arguments.subFlow ].transitions;
			var alreadyFound = transitions.filter( function( item ){
				return item.from == from && item.to == to;
			}  ).len();

			if ( !alreadyFound ) {
				transitions.append({ from=arguments.from, to=arguments.to } );
			}
		}

		subFlowQuickLinks[ "" ] = result;

		for( var step in steps ) {
			stepQuickLinks[ step.getId() ] = step;
			subflows[ step.getSubflowRef() ] = subflows[ step.getSubflowRef() ] ?: [];
			parentChildren[ step.getParentSubflowRef() ] = parentChildren[ step.getParentSubflowRef() ] ?: [];

			subflows[ step.getSubflowRef() ].append( step.getId() );
			parentChildren[ step.getParentSubflowRef() ].append( step.getSubflowRef() )
		}

		result.steps = subflows[ "" ] ?: []
		result.subFlows = _recurseParentChildren( "" );

		var isFirst = true;
		for( var step in steps ) {
			stepLineage[ step.getId() ] = _getSubflowLineage( step.getSubflowRef() );
			if ( ArrayLast( stepLineage[ step.getId() ] ) != "" ) {
				stepLineage[ step.getId() ].append( "" );
			}

			if ( isFirst || step.getStart() ) {
				if ( stepLineage[ step.getId() ].len() > 1 ) {
					result.startSteps.append( "_subflow" & stepLineage[ step.getId() ][ stepLineage[ step.getId() ].len()-1 ] );
				} else {
					result.startSteps.append( step.getId() );
				}
			}
			isFirst = false;
		}

		for( var step in cfflowSteps ) {
			var stepId = step.getId();
			for( var action in step.getActions() ) {
				var results = [ action.getDefaultResult() ];
				results.append( action.getConditionalResults(), true );
				for( var wfResult in results ) {
					for( var transition in wfResult.getTransitions() ) {
						if ( transition.getStatus() == "active" ) {
							if ( stepQuickLinks[ stepId ].getSubflowRef() == stepQuickLinks[ transition.getStep() ].getSubflowRef() ) {
								_addTransition( stepQuickLinks[ stepId ].getSubflowRef(), stepId, transition.getStep() );
							} else {
								var downgraded = _downgradeTransitionPath( stepId, transition.getStep() );
								if ( downgraded.count() ) {
									_addTransition( downgraded.subFlow, downgraded.from, downgraded.to );
								}
							}
						}
					}
				}
			}
		}

		return {
			  structure      = result
			, stepQuickLinks = stepQuickLinks
		};
	}

	private string function _renderState( struct stateInfo, string webflowId, struct stepQuickLinks, numeric depth, boolean collapseSubFlows, struct stepStatuses ) {
		var pad = RepeatString( " ", arguments.depth*4 );
		var innerPad = pad;
		var nl  = Chr( 10 );
		var plantUml = "";

		if ( stateInfo.id.len() ) {
			var subflowTitle = $translateResource( uri="webflow.subflow.#stateInfo.id#:title", defaultValue=stateInfo.id );

			if ( compare( subflowTitle, stateInfo.id ) ) {
				plantUml = pad & 'state "#subflowTitle#" as _subflow#stateInfo.id#';
			} else {
				plantUml = pad & 'state _subflow#stateInfo.id#';
			}

			if ( arguments.collapseSubFlows ) {
				plantUml &= "<<subflow>>";
				var subflowDescription = $translateResource( uri="webflow.subflow.#stateInfo.id#:description", defaultValue="" );
				if ( Len( subflowDescription ) ) {
					plantUml &= ": #subflowDescription#";
				}

				return plantUml & nl;
			}

			plantUml &= " {" & nl;
			innerPad &= "    ";
		}

		for( var stepId in stateInfo.steps ) {
			var stepLabel = confService.getStepLabel( stepId, webflowId );
			var stepDescription = confService.getStepDescription( stepId, webflowId );
			plantUml &= innerPad & 'state ';

			if ( compare( stepLabel, stepId ) ) {
				plantUml &= '"#stepLabel#" as #stepId#';
			} else {
				plantUml &= stepId;
			}

			if ( Len( Trim( stepStatuses[ stepId ] ?: "" ) ) ) {
				plantUml &= "<<#stepStatuses[ stepId ]#>>";
			}

			if ( Len( Trim( stepDescription ) ) ) {
				plantUml &= ": " & stepDescription;
			}

			plantUml &= nl;
		}

		for( var subflow in stateInfo.subflows ) {
			plantUml &= _renderState( subflow, webflowId, stepQuickLinks, depth+1, collapseSubFlows, stepStatuses );
		}

		if ( StructKeyExists( stateInfo, "startSteps" ) ) {
			for( var startStep in stateInfo.startSteps ) {
				plantUml &= innerPad & "[*] --> #startStep#" & nl;
			}
		}

		for( var i=1; i<=stateInfo.steps.len(); i++ ) {
			var stepId = stateInfo.steps[ i ];
			var step   = stepQuickLinks[ stepId ];

			if ( !StructKeyExists( stateInfo, "startSteps" ) ) {
				if ( i==1 || step.getStart() || step.getSubflowEntryPoint() ) {
					plantUml &= innerPad & "[*] --> #stepId#" & nl;
				}
			}
			if ( i==stateInfo.steps.len() || step.getFinish() || step.getSubflowExitPoint() ) {
				plantUml &= innerPad & "#stepId# --> [*]" & nl;
			}
		}
		for( var transition in stateInfo.transitions ) {
			plantUml &= innerPad & "#transition.from# --> #transition.to#" & nl;
		}

		if ( stateInfo.id.len() ) {
			plantUml &= pad & "}" & nl;
		}

		return plantUml;
	}

		private string function _getDefaultStyle() {
		return 'skinparam Padding 2
skinparam state {
  StartColor ##2b7dbc
  EndColor ##2b7dbc
  ArrowColor ##b2b6bf
  BorderColor ##2c3d4e
  BackgroundColor ##f5f5f5
  BackgroundColor<<active>> ##dff0d8
  BackgroundColor<<pending>> ##ffffff
  BackgroundColor<<complete>> ##f5f5f5
  BackgroundColor<<skipped>> ##ffffff
  BorderColor<<skipped>> ##cccccc
  FontColor<<skipped>> ##cccccc
  AttributeFontColor<<skipped>> ##cccccc
  BackgroundColor<<pending>> ##ffffff
  BorderColor<<pending>> ##cccccc
  FontColor<<pending>> ##cccccc
  AttributeFontColor<<pending>> ##cccccc
  BackgroundColor<<subflow>> ##ffffff
  BorderColor<<subflow>> ##b2b6bf
  FontColor<<subflow>> ##b2b6bf
  AttributeFontColor<<subflow>> ##b2b6bf
  FontSize 10
  AttributeFontSize 8
  AttributeFontStyle italic
}';
	}
}