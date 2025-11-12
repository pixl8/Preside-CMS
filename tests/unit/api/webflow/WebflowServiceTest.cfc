component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow service", function() {

			beforeEach( function(){
				_cfflow = CreateEmptyMock( "cfflow.models.CfFlow" );
				_webflowConverter = CreateEmptyMock( "preside.system.services.webflow.spec.WebflowToCfFlowConverter" );
				_webflowLibrary = CreateEmptyMock( "preside.system.services.webflow.spec.WebflowSpecLibrary" );
				_systemConfigSrvc = createStub();

				_systemConfigSrvc.$( "saveSetting", true );

				_svc = CreateMock( object=new preside.system.services.webflow.WebflowService(
					  cfflow           = _cfflow
					, webflowConverter = _webflowConverter
					, webflowLibrary   = _webflowLibrary
				) );

				_svc.$( "$getPresideSetting", "" );
				_svc.$( "$getSystemConfigurationService", _systemConfigSrvc );
			} );

			describe( "loadStepDirectory( dir )", function(){
				it( "should read all yml files from the given directory and register the steps found there with the webflow library", function(){
					var dir          = "/resources/webflow/steps";
					var flowFiles    = DirectoryList( dir, false, "path", "*.yml" );

					flowFiles.sort( "textnocase" );

					_webflowLibrary.$( "registerStep" );

					_svc.loadStepDirectory( dir );

					var callLog = _webflowLibrary.$callLog().registerStep;
					expect( callLog.len() ).toBe( flowFiles.len() );

					for( var i=1; i<=flowFiles.len(); i++ ) {
						expect( callLog[i][ 1 ] ).toBe( flowFiles[ i ] );
					}
				} );
			} );

			describe( "loadFlowDirectory( dir )", function(){
				it( "should read all yml files from the given directory and register the flows found there with the webflow library and with cfflow", function(){
					var dir          = "/resources/webflow";
					var flowFiles    = DirectoryList( dir, false, "path", "*.yml" );
					var mockWebFlows = [];
					var mockCfFlows  = [];

					flowFiles.sort( "textnocase" );
					_cfflow.$( "registerWorkflow" );

					for( var flowFilePath in flowFiles ) {
						var mockWebflow = CreateMock( "preside.system.services.webflow.spec.Webflow" );
						var mockCfflow = CreateMock( "cfflow.models.definition.spec.Workflow" );

						mockWebflow.setId( "mockWebflow-" & flowFilePath );
						mockCfflow.setId( "mockCfflow-" & flowFilePath );

						mockWebFlows.append( mockWebFlow );
						mockCfFlows.append( mockCfFlow );
					}

					_webflowLibrary.$( "registerWebflow" ).$results( argumentCollection=mockWebFlows );
					_webflowConverter.$( "convert" ).$results( argumentCollection=mockCfFlows );

					_svc.loadFlowDirectory( ExpandPath( dir ) );

					var callLog = _cfflow.$callLog().registerWorkflow;
					expect( callLog.len() ).toBe( flowFiles.len() );

					for( var i=1; i<=flowFiles.len(); i++ ) {
						expect( callLog[i][ 1 ].getId() ).toBe( "mockCfflow-" & flowFiles[ i ] );
					}
				} );
			} );

		} );
	}

}