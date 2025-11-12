component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow to CfFlow converter", function() {

			beforeEach( function(){
				_cfflowFactory = new cfflow.models.definition.WorkflowFactory();
				_webflowLib = new preside.system.services.webflow.spec.WebflowSpecLibrary(
					  webflowValidator = new cfflow.models.util.JsonSchemaValidator()
					, stepValidator    = new cfflow.models.util.JsonSchemaValidator()
					, subflowValidator = new cfflow.models.util.JsonSchemaValidator()
					, yamlParser       = new cfflow.models.util.YamlParser()
				);
				_converter = CreateMock( object=new preside.system.services.webflow.spec.WebflowToCfFlowConverter(
					cfflowFactory = _cfflowFactory
				) );
			} );

			describe( "registerWebflowAsCfFlow( webflow )", function(){
				describe( "Flow without conditions", function(){
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/simple.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should register basic flow details", function(){
						expect( cfflowDefinition.getId() ).toBe( "preside.webflow.my.simple.webflow" );
						expect( cfflowDefinition.getClass() ).toBe( "preside.standard.flow" );
						expect( cfflowDefinition.getMeta() ).toBe( {
							  title    = "A simple test webflow"
							, category = "test"
						} );
					} );

					it( "should register a single automatic initial action to take the user to the first step", function(){
						expect( cfflowDefinition.getInitialActions().len() ).toBe( 1 );

						var initialAction = cfflowDefinition.getInitialActions()[ 1 ];
						expect( initialAction.getId() ).toBe( "start" );
						expect( initialAction.getIsAutomatic() ).toBe( true );
						expect( initialAction.getConditionalResults().len() ).toBe( 0 );

						var defaultResult = initialAction.getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-1" );
						expect( defaultResult.getTransitions().len() ).toBe( 1 );

						var transition = defaultResult.getTransitions()[ 1 ];
						expect( transition.getStep() ).toBe( "step-1" );
						expect( transition.getStatus() ).toBe( "active" );
					} );

					it( "should register the steps of the flow", function(){
						var steps = cfflowDefinition.getSteps();
						expect( steps.len() ).toBe( 3 );

						expect( steps[1].getId() ).toBe( "step-1" );
						expect( steps[1].hasAutoActionTimers() ).toBe( false );
						expect( steps[1].hasAutoActions() ).toBe( false );

						expect( steps[2].getId() ).toBe( "step-2" );
						expect( steps[2].hasAutoActionTimers() ).toBe( false );
						expect( steps[2].hasAutoActions() ).toBe( false );

						expect( steps[3].getId() ).toBe( "step-3" );
						expect( steps[3].hasAutoActionTimers() ).toBe( false );
						expect( steps[3].hasAutoActions() ).toBe( false );
					} );

					it( "should register a 'next' action for the first step with a default result taking to the next step", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[1].getActions();

						expect( actions.len() ).toBe( 1 );
						expect( actions[1].getId() ).toBe( "next" );
						expect( actions[1].getIsAutomatic() ).toBe( false );
						expect( actions[1].getConditionalResults().len() ).toBe( 0 );

						var defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-2" );

						var transitions = defaultResult.getTransitions();
						expect( transitions.len() ).toBe( 2 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "complete" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should register a 'next' action for the middle step with a default result taking to the next step", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[2].getActions();

						expect( actions.len() ).toBe( 2 );
						expect( actions[2].getId() ).toBe( "next" );
						expect( actions[2].getIsAutomatic() ).toBe( false );
						expect( actions[2].getConditionalResults().len() ).toBe( 0 );

						var defaultResult = actions[2].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-3" );

						var transitions = defaultResult.getTransitions();
						expect( transitions.len() ).toBe( 2 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 1 ].getStatus() ).toBe( "complete" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should register a 'prev' action for the middle step with a default result taking to the next step", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[2].getActions();

						expect( actions.len() ).toBe( 2 );
						expect( actions[1].getId() ).toBe( "prev" );
						expect( actions[1].getIsAutomatic() ).toBe( false );
						expect( actions[1].getConditionalResults().len() ).toBe( 0 );

						var defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-1" );

						var transitions = defaultResult.getTransitions();
						expect( transitions.len() ).toBe( 2 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should ensure the final step has no actions", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[3].getActions();

						expect( actions.len() ).toBe( 0 );
					} );
				} );

				describe( "Straight flow with conditions", function(){
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/simple.conditional.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should register conditional results for steps whose subsequent steps are conditional", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[1].getActions();

						expect( actions.len() ).toBe( 1 );
						expect( actions[1].getId() ).toBe( "next" );
						expect( actions[1].getIsAutomatic() ).toBe( false );
						var conditionalResults = actions[1].getConditionalResults();

						expect( conditionalResults.len() ).toBe( 2 );

						expect( conditionalResults[ 1 ].getId() ).toBe( "step-2" );
						expect( conditionalResults[ 1 ].getCondition().getRef() ).toBe( "test.condition" );

						var transitions = conditionalResults[ 1 ].getTransitions();
						expect( transitions.len() ).toBe( 2 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "complete" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );

						expect( conditionalResults[ 2 ].getId() ).toBe( "step-3" );
						expect( conditionalResults[ 2 ].getCondition().getRef() ).toBe( "test.condition.2" );

						var transitions = conditionalResults[ 2 ].getTransitions();
						expect( transitions.len() ).toBe( 3 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "complete" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "skipped" );

						expect( transitions[ 3 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 3 ].getStatus() ).toBe( "active" );

						// default result
						var defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-4" );

						transitions = defaultResult.getTransitions();
						expect( transitions.len() ).toBe( 4 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "complete" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "skipped" );

						expect( transitions[ 3 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 3 ].getStatus() ).toBe( "skipped" );

						expect( transitions[ 4 ].getStep() ).toBe( "step-4" );
						expect( transitions[ 4 ].getStatus() ).toBe( "active" );
					} );

					it( "should register conditional results for steps whose previous steps are conditional", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[4].getActions();

						expect( actions.len() ).toBe( 2 );
						expect( actions[1].getId() ).toBe( "prev" );
						expect( actions[1].getIsAutomatic() ).toBe( false );
						var conditionalResults = actions[1].getConditionalResults();

						expect( conditionalResults.len() ).toBe( 2 );

						expect( conditionalResults[ 1 ].getId() ).toBe( "step-3" );
						expect( conditionalResults[ 1 ].getCondition().getRef() ).toBe( "test.condition.2" );

						var transitions = conditionalResults[ 1 ].getTransitions();
						expect( transitions.len() ).toBe( 2 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-4" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );

						expect( conditionalResults[ 2 ].getId() ).toBe( "step-2" );
						expect( conditionalResults[ 2 ].getCondition().getRef() ).toBe( "test.condition" );

						var transitions = conditionalResults[ 2 ].getTransitions();
						expect( transitions.len() ).toBe( 3 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-4" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 2 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 3 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 3 ].getStatus() ).toBe( "active" );

						// default result
						var defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-1" );

						transitions = defaultResult.getTransitions();
						expect( transitions.len() ).toBe( 4 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-4" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 2 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 3 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 3 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 4 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 4 ].getStatus() ).toBe( "active" );
					} );
				} );

				describe( "Multi path flow", function() {
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/multi.path.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should only add 'next' step results for steps explicitly listed in 'next' property when supplied", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[2].getActions();

						expect( actions.len() ).toBe( 2 );
						expect( actions[2].getId() ).toBe( "next" );
						expect( actions[2].getIsAutomatic() ).toBe( false );
						expect( actions[2].getConditionalResults().len() ).toBe( 0 );

						var defaultResult = actions[2].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-4" );

						transitions = defaultResult.getTransitions();
						expect( transitions.len() ).toBe( 2 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 1 ].getStatus() ).toBe( "complete" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-4" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should only add 'prev' step results for steps explicitly listed in 'prev' property when supplied", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[3].getActions();

						expect( actions.len() ).toBe( 2 );
						expect( actions[1].getId() ).toBe( "prev" );
						expect( actions[1].getIsAutomatic() ).toBe( false );
						expect( actions[1].getConditionalResults().len() ).toBe( 0 );

						var defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-1" );

						transitions = defaultResult.getTransitions();
						expect( transitions.len() ).toBe( 2 );

						expect( transitions[ 1 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );

						expect( transitions[ 2 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );
				} );

				describe( "Multi finish step flow", function() {
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/multi.finish.steps.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should have first step with just next action with conditional result and default result that skips step 3", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[1].getActions();
						var conditionalResults = "";
						var defaultResult = "";
						var transitions = "";

						expect( actions.len() ).toBe( 1 );
						expect( actions[1].getId() ).toBe( "next" );
						expect( actions[1].getIsAutomatic() ).toBe( false );

						conditionalResults = actions[1].getConditionalResults();
						expect( conditionalResults.len() ).toBe( 1 );
						expect( conditionalResults[ 1 ].getId() ).toBe( "step-2" );
						expect( conditionalResults[ 1 ].getCondition().getRef() ).toBe( "test.condition" );
							transitions = conditionalResults[ 1 ].getTransitions();
							expect( transitions.len() ).toBe( 2 );
							expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
							expect( transitions[ 1 ].getStatus() ).toBe( "complete" );
							expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
							expect( transitions[ 2 ].getStatus() ).toBe( "active" );

						defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-4" );
							transitions = defaultResult.getTransitions();
							expect( transitions.len() ).toBe( 3 );
							expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
							expect( transitions[ 1 ].getStatus() ).toBe( "complete" );
							expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
							expect( transitions[ 2 ].getStatus() ).toBe( "skipped" );
							expect( transitions[ 3 ].getStep() ).toBe( "step-4" );
							expect( transitions[ 3 ].getStatus() ).toBe( "active" );
					} );

					it( "should have second step that always returns to step 1 and goes next to step 3", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[2].getActions();
						var conditionalResults = "";
						var defaultResult = "";
						var transitions = "";

						expect( actions.len() ).toBe( 2 );
						expect( actions[1].getId() ).toBe( "prev" );
						expect( actions[1].getIsAutomatic() ).toBe( false );
						expect( actions[2].getId() ).toBe( "next" );
						expect( actions[2].getIsAutomatic() ).toBe( false );

						conditionalResults = actions[1].getConditionalResults();
						expect( conditionalResults.len() ).toBe(0);
						conditionalResults = actions[2].getConditionalResults();
						expect( conditionalResults.len() ).toBe(0);

						defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-1" );
							transitions = defaultResult.getTransitions();
							expect( transitions.len() ).toBe( 2 );
							expect( transitions[ 1 ].getStep() ).toBe( "step-2" );
							expect( transitions[ 1 ].getStatus() ).toBe( "pending" );
							expect( transitions[ 2 ].getStep() ).toBe( "step-1" );
							expect( transitions[ 2 ].getStatus() ).toBe( "active" );

						defaultResult = actions[2].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-3" );
							transitions = defaultResult.getTransitions();
							expect( transitions.len() ).toBe( 2 );
							expect( transitions[ 1 ].getStep() ).toBe( "step-2" );
							expect( transitions[ 1 ].getStatus() ).toBe( "complete" );
							expect( transitions[ 2 ].getStep() ).toBe( "step-3" );
							expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should have third step without any actions because it is final", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[3].getActions();

						expect( actions.len() ).toBe( 0 );
					} );

					it( "should have fourth step that always returns to step 1 and goes next to step 5", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[4].getActions();
						var conditionalResults = "";
						var defaultResult = "";
						var transitions = "";

						expect( actions.len() ).toBe( 2 );
						expect( actions[1].getId() ).toBe( "prev" );
						expect( actions[1].getIsAutomatic() ).toBe( false );
						expect( actions[2].getId() ).toBe( "next" );
						expect( actions[2].getIsAutomatic() ).toBe( false );

						conditionalResults = actions[1].getConditionalResults();
						expect( conditionalResults.len() ).toBe(0);
						conditionalResults = actions[2].getConditionalResults();
						expect( conditionalResults.len() ).toBe(0);

						defaultResult = actions[1].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-1" );
							transitions = defaultResult.getTransitions();
							expect( transitions.len() ).toBe( 2 );
							expect( transitions[ 1 ].getStep() ).toBe( "step-4" );
							expect( transitions[ 1 ].getStatus() ).toBe( "pending" );
							expect( transitions[ 2 ].getStep() ).toBe( "step-1" );
							expect( transitions[ 2 ].getStatus() ).toBe( "active" );

						defaultResult = actions[2].getDefaultResult();
						expect( defaultResult.getId() ).toBe( "step-5" );
							transitions = defaultResult.getTransitions();
							expect( transitions.len() ).toBe( 2 );
							expect( transitions[ 1 ].getStep() ).toBe( "step-4" );
							expect( transitions[ 1 ].getStatus() ).toBe( "complete" );
							expect( transitions[ 2 ].getStep() ).toBe( "step-5" );
							expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should have fifth step that has no actions because it is last step", function(){
						var steps = cfflowDefinition.getSteps();
						var actions = steps[5].getActions();

						expect( actions.len() ).toBe( 0 );
					} );
				} );

				describe( "Multi start step flow", function() {
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/multi.start.steps.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should have an initial action with two conditional results and one default", function(){
						var initialActions = cfflowDefinition.getInitialActions();

						expect( initialActions.len() ).toBe( 1 );
						expect( initialActions[ 1 ].getId() ).toBe( "start" );
						expect( initialActions[ 1 ].getIsAutomatic() ).toBe( true );

						var conditionalResults = initialActions[ 1 ].getConditionalResults();
						var defaultResult = initialActions[ 1 ].getDefaultResult();
						var transitions = defaultResult.getTransitions();

						expect( defaultResult.getId() ).toBe( "step-3" );
						expect( transitions.len() ).toBe( 3 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 3 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 3 ].getStatus() ).toBe( "active" );

						expect( conditionalResults.len() ).toBe( 2 );
						expect( conditionalResults[ 1 ].getId() ).toBe( "step-1" );
						expect( conditionalResults[ 1 ].getCondition().getRef() ).toBe( "test.condition" );
						expect( conditionalResults[ 2 ].getId() ).toBe( "step-2" );
						expect( conditionalResults[ 2 ].getCondition().getRef() ).toBe( "test.condition.2" );

						transitions = conditionalResults[ 1 ].getTransitions();
						expect( transitions[ 1 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 1 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 2 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 3 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 3 ].getStatus() ).toBe( "active" );

						transitions = conditionalResults[ 2 ].getTransitions();
						expect( transitions.len() ).toBe( 3 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 2 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 3 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 3 ].getStatus() ).toBe( "active" );
					} );

					it( "should have all initial steps with no prev action", function(){
						var steps = cfflowDefinition.getSteps();

						for( var i in [ 1, 2, 3] ) {
							var step = steps[ i ];
							var actions = step.getActions();

							expect( actions.len() ).toBe( 1 );
							expect( actions[ 1 ].getId() ).toBe( "next" );

							expect( actions[ 1 ].getConditionalResults().len() ).toBe( 0 );
							var defaultResult = actions[ 1 ].getDefaultResult();
							var transitions = defaultResult.getTransitions();

							expect( transitions.len() ).toBe( 2 );
							expect( transitions[1].getStep() ).toBe( "step-#i#" );
							expect( transitions[1].getStatus() ).toBe( "complete" );
							expect( transitions[2].getStep() ).toBe( "step-4" );
							expect( transitions[2].getStatus() ).toBe( "active" );
						}
					} );
				} );

				describe( "Conditional start step flow", function() {
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/conditional.start.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should have an initial action with two conditional results and one default", function(){
						var initialActions = cfflowDefinition.getInitialActions();

						expect( initialActions.len() ).toBe( 1 );
						expect( initialActions[ 1 ].getId() ).toBe( "start" );
						expect( initialActions[ 1 ].getIsAutomatic() ).toBe( true );

						var conditionalResults = initialActions[ 1 ].getConditionalResults();
						var defaultResult = initialActions[ 1 ].getDefaultResult();
						var transitions = defaultResult.getTransitions();

						expect( defaultResult.getId() ).toBe( "step-3" );
						expect( transitions.len() ).toBe( 3 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 3 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 3 ].getStatus() ).toBe( "active" );

						expect( conditionalResults.len() ).toBe( 2 );
						expect( conditionalResults[ 1 ].getId() ).toBe( "step-1" );
						expect( conditionalResults[ 1 ].getCondition().getRef() ).toBe( "test.condition" );
						expect( conditionalResults[ 2 ].getId() ).toBe( "step-2" );
						expect( conditionalResults[ 2 ].getCondition().getRef() ).toBe( "test.condition.2" );

						transitions = conditionalResults[ 1 ].getTransitions();
						expect( transitions.len() ).toBe( 1 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "active" );

						transitions = conditionalResults[ 2 ].getTransitions();
						expect( transitions.len() ).toBe( 2 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 1 ].getStatus() ).toBe( "skipped" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should have first step with only a next action", function(){
						var step = cfflowDefinition.getSteps()[1];
						var actions = step.getActions();

						expect( actions.len() ).toBe( 1 );
						expect( actions[ 1 ].getId() ).toBe( "next" );
					} );

					it( "should have a second step with a conditional previous action", function(){
						var step = cfflowDefinition.getSteps()[2];
						var actions = step.getActions();

						expect( actions.len() ).toBe( 2 );
						expect( actions[ 2 ].getId() ).toBe( "next" );

						expect( actions[ 1 ].getId() ).toBe( "prev" );
						expect( actions[ 1 ].hasCondition() ).toBe( true );
						expect( actions[ 1 ].getCondition().getRef() ).toBe( "test.condition" );

						expect( actions[ 1 ].getConditionalResults().len() ).toBe( 0 );

						var defaultResult = actions[ 1 ].getDefaultResult();
						var transitions   = defaultResult.getTransitions();

						expect( defaultResult.getId() ).toBe( "step-1" );

						expect( transitions.len() ).toBe( 2 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );
					} );

					it( "should have a third step with a conditional previous action", function(){
						var step = cfflowDefinition.getSteps()[3];
						var actions = step.getActions();

						expect( actions.len() ).toBe( 2 );
						expect( actions[ 2 ].getId() ).toBe( "next" );

						expect( actions[ 1 ].getId() ).toBe( "prev" );
						expect( actions[ 1 ].hasCondition() ).toBe( true );
						expect( actions[ 1 ].getCondition().getRef() ).toBe( "test.condition.2" );
						expect( actions[ 1 ].getCondition().getOrConditions().len() ).toBe( 1 );
						expect( actions[ 1 ].getCondition().getOrConditions()[1].getRef() ).toBe( "test.condition" );

						expect( actions[ 1 ].getConditionalResults().len() ).toBe( 1 );
						var conditionalResult = actions[ 1 ].getConditionalResults()[ 1 ];
						expect( conditionalResult.getId() ).toBe( "step-2" );
						var transitions   = conditionalResult.getTransitions();
						expect( transitions.len() ).toBe( 2 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "active" );

						var defaultResult = actions[ 1 ].getDefaultResult();
						var transitions   = defaultResult.getTransitions();

						expect( defaultResult.getId() ).toBe( "step-1" );

						expect( transitions.len() ).toBe( 3 );
						expect( transitions[ 1 ].getStep() ).toBe( "step-3" );
						expect( transitions[ 1 ].getStatus() ).toBe( "pending" );
						expect( transitions[ 2 ].getStep() ).toBe( "step-2" );
						expect( transitions[ 2 ].getStatus() ).toBe( "pending" );
						expect( transitions[ 3 ].getStep() ).toBe( "step-1" );
						expect( transitions[ 3 ].getStatus() ).toBe( "active" );
					} );

				} );

				describe( "Steps with preactions", function() {
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/step.with.preactions.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should add pre-functions to any steps that transition to it on 'next' steps where actions have 'both' or 'forward', or no direction defined", function(){
						var step1To3Result = cfflowDefinition.getSteps()[ 1 ].getActions()[ 1 ].getDefaultResult();
						var step3Transition = step1To3Result.getTransitions()[ 3 ];

						expect( step3Transition.getStep() ).toBe( "step-3" );
						expect( step3Transition.getStatus() ).toBe( "active" );

						var preFunctions = step1To3Result.getPreFunctions();

						expect( preFunctions.len() ).toBe( 2 );
						expect( preFunctions[ 1 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 1 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 1 ].getArgs() ).toBe( {
							  event = "test.event"
							, args  = { arg="test" }
						} );
						expect( preFunctions[ 1 ].getCondition().getRef() ).toBe( "string.EndsWith" );
						expect( preFunctions[ 2 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 2 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 2 ].getArgs() ).toBe( {
							  event = "test.event.2"
							, args  = { arg="test.2" }
						} );
					} );

					it( "should add pre-functions to any steps that transition to it on 'prev' steps where actions have 'both' or 'back' direction", function(){
						var step4To3Result = cfflowDefinition.getSteps()[ 4 ].getActions()[ 1 ].getDefaultResult();
						var step3Transition = step4To3Result.getTransitions()[ 2 ];

						expect( step3Transition.getStep() ).toBe( "step-3" );
						expect( step3Transition.getStatus() ).toBe( "active" );

						var preFunctions = step4To3Result.getPreFunctions();

						expect( preFunctions.len() ).toBe( 2 );

						expect( preFunctions[ 1 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 1 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 1 ].getArgs() ).toBe( {
							  event = "test.event.2"
							, args  = { arg="test.2" }
						} );
						expect( preFunctions[ 2 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 2 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 2 ].getArgs() ).toBe( {
							  event = "test.event.3"
							, args  = { arg="test.3" }
						} );
					} );
				} );

				describe( "Steps with postactions", function() {
					beforeEach( function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/step.with.postactions.webflow.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );
						cfflowDefinition = _converter.convert( webflowDefinition );
					} );

					it( "should add pre-functions to any outbound next action results for actions that are either forward or both directional", function(){
						var step3To4Result = cfflowDefinition.getSteps()[ 3 ].getActions()[ 2 ].getDefaultResult();
						var step3Transition = step3To4Result.getTransitions()[ 2 ];

						expect( step3Transition.getStep() ).toBe( "step-4" );
						expect( step3Transition.getStatus() ).toBe( "active" );

						var preFunctions = step3To4Result.getPreFunctions();

						expect( preFunctions.len() ).toBe( 2 );
						expect( preFunctions[ 1 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 1 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 1 ].getArgs() ).toBe( {
							  event = "test.event"
							, args  = { arg="test" }
						} );
						expect( preFunctions[ 1 ].getCondition().getRef() ).toBe( "preside.IsLoggedIn" );

						expect( preFunctions[ 2 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 2 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 2 ].getArgs() ).toBe( {
							  event = "test.event.2"
							, args  = { arg="test.2" }
						} );
					} );

					it( "should add pre-functions to any outbound prev action results for actions that are either back or both directional", function(){
						var step3To1Result = cfflowDefinition.getSteps()[ 3 ].getActions()[ 1 ].getDefaultResult();
						var step3Transition = step3To1Result.getTransitions()[ 2 ];

						expect( step3Transition.getStep() ).toBe( "step-1" );
						expect( step3Transition.getStatus() ).toBe( "active" );

						var preFunctions = step3To1Result.getPreFunctions();

						expect( preFunctions.len() ).toBe( 2 );
						expect( preFunctions[ 1 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 1 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 1 ].getArgs() ).toBe( {
							  event = "test.event"
							, args  = { arg="test" }
						} );
						expect( preFunctions[ 1 ].getCondition().getRef() ).toBe( "preside.IsLoggedIn" );

						expect( preFunctions[ 2 ].getRef() ).toBe( "coldbox.handler" );
						expect( preFunctions[ 2 ].getPreOrPost() ).toBe( "pre" );
						expect( preFunctions[ 2 ].getArgs() ).toBe( {
							  event = "test.event.3"
							, args  = { arg="test.3" }
						} );
					} );
				} );

				describe( "Explicit next steps without a default", function(){
					it( "should raise an informative error", function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/bad/explicit.next.steps.all.conditional.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );

						expect( function(){
							_converter.convert( webflowDefinition );
						} ).toThrow( "preside.webflow.no.default.next.step" );
					} );
				} );

				describe( "Explicit next steps with more than one default", function(){
					it( "should raise an informative error", function(){
						var yamlFilePath = ExpandPath( "/resources/webflow/bad/explicit.next.steps.multiple.unconditional.yml" );

						webflowDefinition = _webflowLib.registerWebflow( yamlFilePath );

						expect( function(){
							_converter.convert( webflowDefinition );
						} ).toThrow( "preside.webflow.multiple.default.next.steps" );
					} );
				} );

			} );
		} );
	}

}