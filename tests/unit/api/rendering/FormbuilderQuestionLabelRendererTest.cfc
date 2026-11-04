component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "form builder question labels", function(){
			it( "encodes brackets, quotes and entities in the question label", function(){
				var renderer = _getRenderer();
				var rendered = renderer._renderLabel( field_id="q-1", field_label='Tom & "Jerry" <em>' );
				var encoded  = EncodeForHtml( 'Tom & "Jerry" <em>' );

				expect( rendered ).toBe( '#encoded# (<code>q-1</code>)' );
			} );

			it( "keeps the code element around the field id", function(){
				var renderer = _getRenderer();
				var label    = renderer._renderLabel( field_id="email_address", field_label="Email" );

				expect( label ).toBe( "Email (<code>email_address</code>)" );
			} );
		} );
	}

	private any function _getRenderer() {
		var renderer = new preside.system.handlers.renderers.labels.formbuilder_question();

		makePublic( renderer, "_renderLabel" );

		return renderer;
	}

}
