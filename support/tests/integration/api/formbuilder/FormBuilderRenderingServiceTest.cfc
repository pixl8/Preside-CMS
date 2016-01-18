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