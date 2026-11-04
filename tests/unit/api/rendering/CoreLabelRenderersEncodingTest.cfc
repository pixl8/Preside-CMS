component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		var unsafe  = 'Tom & "Jerry" <em>';
		var encoded = EncodeForHtml( unsafe );

		describe( "system alert labels", function(){
			it( "encodes the alert type used as the fallback title", function(){
				var renderer = _getRenderer( "system_alert" );

				renderer.$( "translateResource", unsafe );

				expect( renderer._renderLabel( type=unsafe ) ).toBe( encoded );
			} );
		} );

		describe( "workflow instance labels", function(){
			it( "encodes the workflow title and the owner", function(){
				var renderer = _getRenderer( "cfflow_instance_label" );

				renderer.$( "translateResource", unsafe );
				renderer.$( "renderContent", unsafe );

				expect( renderer._renderLabel( reference="ref", owner="owner" ) ).toBe( "#encoded#: #encoded#" );
			} );
		} );

		describe( "webflow step labels", function(){
			it( "encodes the step label", function(){
				var renderer           = _getRenderer( "WebflowStep" );
				var mockConfigService  = createStub();

				mockConfigService.$( "getStepLabel", unsafe );
				renderer.$property( propertyName="webflowConfigurationService", mock=mockConfigService );

				expect( renderer._renderLabel( step_id="step", webflow_id="flow" ) ).toBe( encoded );
			} );
		} );

		describe( "email layout config item labels", function(){
			it( "encodes the item and the template name", function(){
				var renderer = _getRenderer( "email_layout_config_item" );

				renderer.$( "translateResource" ).$args(
					  uri  = "preside-objects.email_layout_config_item:renderer.labels.template_prefix"
					, data = [ unsafe ]
				).$results( "Template: #unsafe#" );

				expect( renderer._renderLabel( template_name=unsafe, item=unsafe ) ).toBe( EncodeForHtml( "Template: #unsafe# - #unsafe#" ) );
			} );
		} );
	}

	private any function _getRenderer( required string rendererName ) {
		var renderer = createMock( object=CreateObject( "component", "preside.system.handlers.renderers.labels.#arguments.rendererName#" ) );

		makePublic( renderer, "_renderLabel" );

		return renderer;
	}

}
