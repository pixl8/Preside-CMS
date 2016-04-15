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

		describe( "modifyTab()", function(){

			it( "should alter the given tab (by id) by appending the passed arguments to the tab", function(){
				var definition = _getFormDefinition();

				definition.addTab( id="anotherTab" )
				          .addTab( id="mytab" )
				          .addTab( id="tab2" )
				          .addTab( id="tabtab" );

				definition.modifyTab( id="tab2", title="Test", description="Test description" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[
					  { id="anotherTab", fieldsets=[] }
					, { id="mytab", fieldsets=[] }
					, { id="tab2", fieldsets=[], title="Test", description="Test description" }
					, { id="tabtab", fieldsets=[] }
				] } );
			} );

			it( "should create the tab when it does not exist", function(){
				var definition = _getFormDefinition();

				definition.addTab( id="anotherTab" )
				          .addTab( id="mytab" )
				          .addTab( id="tab2" )
				          .addTab( id="tabtab" );

				definition.modifyTab( id="non existant", title="Test", description="Test description" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[
					  { id="anotherTab", fieldsets=[] }
					, { id="mytab", fieldsets=[] }
					, { id="tab2", fieldsets=[] }
					, { id="tabtab", fieldsets=[] }
					, { id="non existant", fieldsets=[], title="Test", description="Test description" }
				] } );
			} );


			it( "should return self so that methods can be chained", function(){
				var definition = _getFormDefinition();
				var result     = definition.addTab( id="mytab" )
				                           .modifyTab( id="mytab", title="Hello?" );

				expect( result ).toBe( definition );
			} );

		} );

		describe( "addFieldset()", function(){

			it( "should append a basic fieldset definition to the end of the given tab's fieldset array", function(){
				var definition = _getFormDefinition( { tabs=[ { id="test", fieldsets=[] } ] } );

				definition.addFieldset( id="myfieldset", tab="test" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[{ id="test", fieldsets=[{ id="myfieldset", fields=[] }] }] } );
			} );

			it( "should include any arguments passed in the fieldset definition", function(){
				var definition = _getFormDefinition( { tabs=[ { id="test", fieldsets=[] } ] } );
				var args       = { id="myfieldset", tab="test", title="My fieldset title", fields=[ { name="myfield" } ] };
				var expectedFieldset = Duplicate( args );

				expectedFieldset.delete( "tab" );

				definition.addFieldset( argumentCollection=args );

				expect( definition.getRawDefinition() ).toBe( { tabs=[ { id="test", fieldsets=[ expectedFieldset ] } ] } );
			} );

			it( "should create the tab if it does not already exist", function(){
				var definition = _getFormDefinition();

				definition.addFieldset( id="myfieldset", tab="newtab" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[{ id="newtab", fieldsets=[{ id="myfieldset", fields=[] }] }] } );
			} );

			it( "should return self so that methods can be chained", function(){
				var definition = _getFormDefinition();
				var result     = definition.addFieldset( id="myfieldset", tab="sometab" );

				expect( result ).toBe( definition );
			} );
		} );

		describe( "deleteFieldset()", function(){

			it( "should remove the given fieldset that lives in the given tab", function(){
				var definition = _getFormDefinition({ tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]});

				definition.deleteFieldset( id="testfieldset2", tab="testtab2" );

				expect( definition.getRawDefinition() ).toBe({ tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[]}
				]});
			} );

			it( "should do nothing if the tab is not found", function(){
				var raw = { tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]};
				var definition = _getFormDefinition( raw );

				definition.deleteFieldset( id="testfieldset2", tab="non.existing" );

				expect( definition.getRawDefinition() ).toBe( raw );
			} );

			it( "should do nothing if the fieldset is not found within the tab", function(){
				var definition = _getFormDefinition({ tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]});

				definition.deleteFieldset( id="nonexisting", tab="testtab2" );

				expect( definition.getRawDefinition() ).toBe( { tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]});
			} );

			it( "should return self so that methods can be chained", function(){
				var definition = _getFormDefinition({ tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]});
				var result = definition.deleteFieldset( id="myfieldset", tab="whatever" );

				expect( result ).toBe( definition );
			} );

		} );

		describe( "modifyFieldset()", function(){

			it( "should alter the given fieldset (by id and tab) by appending the passed arguments to the fieldset", function(){
				var definition = _getFormDefinition({ tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]});

				definition.modifyFieldset( id="testfieldset2", tab="testtab2", title="test fieldset title", fields=[ { name="testfield" } ] );

				expect( definition.getRawDefinition() ).toBe( { tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", title="test fieldset title", fields=[{ name="testfield" }]}]}
				]} );
			} );

			it( "should create both the tab and fieldset if neither exist", function(){
				var definition = _getFormDefinition({ tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]});

				definition.modifyFieldset( id="newfieldset", tab="newtab", title="test fieldset title", fields=[ { name="testfield" } ] );

				expect( definition.getRawDefinition() ).toBe( { tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
					, { id="newtab", fieldsets=[{id="newfieldset", title="test fieldset title", fields=[{ name="testfield" }]}]}
				]} );
			} );

			it( "should return self so that methods can be chained", function(){
				var definition = _getFormDefinition({ tabs=[
					  { id="test", fieldsets=[{id="test", fields=[]}]}
					, { id="testtab2", fieldsets=[{id="testfieldset2", fields=[]}]}
				]});
				var result = definition.modifyFieldset( id="newfieldset", tab="newtab", title="test fieldset title", fields=[ { name="testfield" } ] );

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