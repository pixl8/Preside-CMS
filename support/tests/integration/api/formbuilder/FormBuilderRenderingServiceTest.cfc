component extends="testbox.system.BaseSpec"{

	function run(){

		describe( "listFormLayouts", function(){
			it( "should return an empty array when no viewlets exist in the system that match the convention based viewlet pattern, [formbuilder.layouts.form.*]", function(){
				var service = getService();

				expect( service.listFormLayouts() ).toBe( [] );
			} );

			it( "should return an array containing a struct for each viewlet that exists that matches the viewlet pattern, with keys for id, viewlet and title that is translated through i18n plugin", function(){
				var service         = getService();
				var matchedViewlets = [
					  "formbuilder.layouts.form.default"
					, "formbuilder.layouts.form.compact"
					, "formbuilder.layouts.form.custom"
				];
				var expectedResult  = [
					  { id="compact", viewlet="formbuilder.layouts.form.compact", title="Translated compact" }
					, { id="custom" , viewlet="formbuilder.layouts.form.custom" , title="Translated custom"  }
					, { id="default", viewlet="formbuilder.layouts.form.default", title="Translated default" }
				];

				service.$( "$translateResource" ).$args( uri="formbuilder.layouts.form:default.title", defaultValue="default" ).$results( "Translated default" );
				service.$( "$translateResource" ).$args( uri="formbuilder.layouts.form:compact.title", defaultValue="compact" ).$results( "Translated compact" );
				service.$( "$translateResource" ).$args( uri="formbuilder.layouts.form:custom.title" , defaultValue="custom"  ).$results( "Translated custom"  );

				mockViewletsService.$( "listPossibleViewlets" ).$args( filter="^formbuilder\.layouts\.form\." ).$results( matchedViewlets );

				expect( service.listFormLayouts() ).toBe( expectedResult );
			} );
		} );

		describe( "listFormFieldLayouts", function(){
			it( "should return an empty array when no viewlets exist in the system that match the convention based viewlet patterns, [formbuilder.layouts.formfield.*]", function(){
				var service = getService();

				expect( service.listFormFieldLayouts( itemType="textinput" ) ).toBe( [] );
			} );

			it( "should return a combined array of layouts that are both generic and that match the given item type", function(){
				var service         = getService();
				var matchedViewlets = [
					  "formbuilder.layouts.formfield.default"
					, "formbuilder.layouts.formfield.twocol"
					, "formbuilder.layouts.formfield.textinput.default"
					, "formbuilder.layouts.formfield.textinput.fancy"
					, "formbuilder.layouts.formfield.textarea.wholesome"
				];
				var expectedResult  = [
					  { id="default", viewlet="formbuilder.layouts.formfield.textinput.default", title="Translated default" }
					, { id="fancy"  , viewlet="formbuilder.layouts.formfield.textinput.fancy"  , title="Translated fancy"   }
					, { id="twocol" , viewlet="formbuilder.layouts.formfield.twocol"           , title="Translated twocol"  }
				];

				service.$( "$translateResource" ).$args( uri="formbuilder.layouts.formfield:default.title", defaultValue="default" ).$results( "Translated default" );
				service.$( "$translateResource" ).$args( uri="formbuilder.layouts.formfield:fancy.title"  , defaultValue="fancy"   ).$results( "Translated fancy"   );
				service.$( "$translateResource" ).$args( uri="formbuilder.layouts.formfield:twocol.title" , defaultValue="twocol"  ).$results( "Translated twocol"  );

				mockViewletsService.$( "listPossibleViewlets" ).$args( filter="^formbuilder\.layouts\.formfield\." ).$results( matchedViewlets );

				expect( service.listFormFieldLayouts( itemType="textinput" ) ).toBe( expectedResult );
			} );
		} );

		describe( "getItemTypeViewlet", function(){

			it( "should return 'formbuilder.item-types.(theitemtype).renderInput', when the given context is 'input'", function(){
				var expected = "formbuilder.item-types.myitemtype.renderInput";
				var actual   = getService().getItemTypeViewlet( "myitemtype", "input" );

				expect( actual ).toBe( expected );
			} );

			it( "should return 'formbuilder.item-types.(theitemtype).renderAdminPlaceholder', when the given context is 'adminPlaceholder'", function(){
				var expected = "formbuilder.item-types.myitemtype.renderAdminPlaceholder";
				var actual   = getService().getItemTypeViewlet( "myitemtype", "adminPlaceholder" );

				expect( actual ).toBe( expected );
			} );

			it( "should return 'formbuilder.item-types.(theitemtype).renderResponse', when the given context is 'response'", function(){
				var expected = "formbuilder.item-types.myitemtype.renderResponse";
				var actual   = getService().getItemTypeViewlet( "myitemtype", "response" );

				expect( actual ).toBe( expected );
			} );
		} );

		describe( "getFormFieldLayoutViewlet", function(){
			it( "should return the viewlet specified for the item type and layout combination", function(){
				var service  = getService();
				var itemType = "myitemtype";
				var layouts  = [
					  { id="blah"   , viewlet="test.viewlet.1" }
					, { id="default", viewlet="test.viewlet.2" }
					, { id="test"   , viewlet="test.viewlet.3" }
					, { id="another", viewlet="test.viewlet.4" }
				];

				service.$( "listFormFieldLayouts" ).$args(
					itemType=itemType
				).$results( layouts );

				var viewlet = service.getFormFieldLayoutViewlet(
					  itemType = "myitemtype"
					, layout   = "test"
				);

				expect( viewlet ).toBe( "test.viewlet.3" );
			} );

			it( "should return [formbuilder.layouts.formfield.default] when no layout matches the given arguments", function(){
				var service  = getService();
				var itemType = "myitemtype";
				var layouts  = [
					  { id="blah"   , viewlet="test.viewlet.1" }
					, { id="default", viewlet="test.viewlet.2" }
					, { id="test"   , viewlet="test.viewlet.3" }
					, { id="another", viewlet="test.viewlet.4" }
				];

				service.$( "listFormFieldLayouts" ).$args(
					itemType=itemType
				).$results( layouts );

				var viewlet = service.getFormFieldLayoutViewlet(
					  itemType = "myitemtype"
					, layout   = "somelayoutthatdoesnotexist"
				);

				expect( viewlet ).toBe( "formbuilder.layouts.formfield.default" );
			} );
		} );


		describe( "getFormLayoutViewlet", function(){
			it( "should return the viewlet defined for the given form layout id", function(){
				var service  = getService();
				var layout   = "test";
				var layouts  = [
					  { id="blah"   , viewlet="test.viewlet.one" }
					, { id="default", viewlet="test.viewlet.two" }
					, { id="test"   , viewlet="test.viewlet.three" }
					, { id="another", viewlet="test.viewlet.four" }
				];

				service.$( "listFormLayouts", layouts );

				var viewlet = service.getFormLayoutViewlet( layout );

				expect( viewlet ).toBe( "test.viewlet.three" );
			} );

			it( "should return [formbuilder.layouts.form.default] when no layout matches the given arguments", function(){
				var service  = getService();
				var layout   = "somelayoutthatdoesnotexist";
				var layouts  = [
					  { id="blah"   , viewlet="test.viewlet.one" }
					, { id="default", viewlet="test.viewlet.two" }
					, { id="test"   , viewlet="test.viewlet.three" }
					, { id="another", viewlet="test.viewlet.four" }
				];

				service.$( "listFormLayouts", layouts );

				var viewlet = service.getFormLayoutViewlet( layout );

				expect( viewlet ).toBe( "formbuilder.layouts.form.default" );
			} );
		} );
	}

	private function getService() {
		variables.mockViewletsService = CreateEmptyMock( "preside.system.services.viewlets.ViewletsService" );
		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderRenderingService(
			viewletsService = mockViewletsService
		) );

		mockViewletsService.$( "listPossibleViewlets", [] );
		service.$( "translateResource", "" );

		return service;
	}

}