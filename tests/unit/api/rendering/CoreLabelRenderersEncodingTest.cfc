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
