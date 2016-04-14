component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){

		describe( "getRawDefinition()", function(){

			it( "should return a struct with nothing but a tabs key that is an empty array, when nothing passed to the defintion object's constructor", function(){
				var definition = _getFormDefinition().getRawDefinition();

				expect( definition ).toBe( { tabs=[] } );
			} );

			it( "should return the structure passed to the object's constructor when no modifying actions made", function(){
				var raw        = { tabs=[ { id="test", fieldsets=[] } ] };
				var definition = _getFormDefinition( raw ).getRawDefinition();

				expect( definition ).toBe( raw );
			} );

		} );

		describe( "addTab()", function(){

			it( "should append a basic tab definition to the end of the forms tab array", function(){
				var definition = _getFormDefinition();

				definition.addTab( id="mytab" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[{ id="myTab", fieldsets=[] }] } );
			} );

			it( "should include any arguments passed in the tab definition", function(){
				var definition = _getFormDefinition();
				var args       = { id="mytab", title="My tab title", fieldsets=[ { id="myfieldset", fields=[] } ] };

				definition.addTab( argumentCollection=args );

				expect( definition.getRawDefinition() ).toBe( { tabs=[ args ] } );
			} );

			it( "should return self so that methods can be chained", function(){
				var definition = _getFormDefinition();
				var result     = definition.addTab( id="mytab" );

				expect( result ).toBe( definition );
			} );

		} );

		describe( "deleteTab()", function(){

			it( "should remove tab definition found by ID", function(){
				var definition = _getFormDefinition();

				definition.addTab( id="anotherTab" )
				          .addTab( id="mytab" )
				          .addTab( id="tab2" )
				          .addTab( id="tabtab" );

				definition.deleteTab( "anotherTab" );
				definition.deleteTab( "tabtab" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[{ id="myTab", fieldsets=[] },{ id="tab2", fieldsets=[] }] } );
			} );

			it( "should do nothing when the passed tab does not exist in the form", function(){
				var definition = _getFormDefinition();

				definition.addTab( id="anotherTab" )
				          .addTab( id="mytab" )
				          .addTab( id="tab2" )
				          .addTab( id="tabtab" );

				definition.deleteTab( "whatever" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[
					  { id="anotherTab", fieldsets=[] }
					, { id="mytab", fieldsets=[] }
					, { id="tab2", fieldsets=[] }
					, { id="tabtab", fieldsets=[] }
				] } );
			} );

			it( "should return self so that methods can be chained", function(){
				var definition = _getFormDefinition();
				var result     = definition.addTab( id="mytab" )
				                           .deleteTab( "mytab" );

				expect( result ).toBe( definition );
			} );

		} );

	}

	private any function _getFormDefinition( struct rawDefinition ) {
		var args = {};

		if ( arguments.keyExists( "rawDefinition" ) ) {
			args.rawDefinition = arguments.rawDefinition;
		}
		return new preside.system.services.forms.FormDefinition( argumentCollection=args );
	}
}