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