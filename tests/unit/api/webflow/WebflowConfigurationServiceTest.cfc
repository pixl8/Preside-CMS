component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow configuration service", function() {

			beforeEach( function(){
				_webflowLibrary = CreateEmptyMock( "preside.system.services.webflow.spec.WebflowSpecLibrary" );
				_formsService = CreateStub();
				_requestContext = CreateStub();
				_svc = CreateMock( object=new preside.system.services.webflow.WebflowConfigurationService(
					  webflowLibrary = _webflowLibrary
					, formsService   = _formsService
				) );

				_flowDao = CreateStub();
				_stepDao = CreateStub();
				_presideObjectService = CreateStub();

				_svc.$( "$getPresideObject" ).$args( "webflow_configuration" ).$results( _flowDao );
				_svc.$( "$getPresideObject" ).$args( "webflow_configuration_step" ).$results( _stepDao );
				_svc.$( "$translateResource", "" );
				_svc.$( "$getPresideObjectService", _presideObjectService );
				_svc.$( "$getRequestContext", _requestContext );
				_svc.$( "_getExistingStepConfigs", {} );

				_presideObjectService.$( "getObjectAttribute", "" );
				_presideObjectService.$( "getObjectAttribute" ).$args( "webflow_configuration_step", "tenant" ).$results( "site" );

				_flowDao.$( "insertData", "" );
				_flowDao.$( "updateData", 0 );
				_flowDao.$( "deleteData", 0 );
				_flowDao.$( "dataExists", true );
				_stepDao.$( "insertData", "" );
				_stepDao.$( "updateData", 0 );
				_stepDao.$( "deleteData", 0 );
				_stepDao.$( "dataExists", true );

				_siteId = CreateUUId();
				_requestContext.$( "getSiteId", _siteId );
			} );

			describe( "initializeSingleton( webflowId )", function(){
				beforeEach( function(){
					_setupMockFlow( singleton=true );
					_mockFlowDbId = CreateUUId();


				} );

				it( "should insert a record for the flow itself", function(){
					var translatedLabel = CreateUUId();
					_svc.$( "_getExistingSingletonFlowForStartupCheck" ).$args( _mockFlowId ).$results({} );
					_svc.$( "$translateResource" ).$args(
						  uri          = "webflow.#_mockFlowId#:title"
						, defaultValue = _mockTitle
					).$results( translatedLabel )

					_svc.initializeSingleton( _mockFlowId );

					expect( _flowDao.$callLog().insertData.len() ).toBe( 1 );
					expect( _flowDao.$callLog().insertData[ 1 ][ 1 ] ).toBe( {
						  webflow_id       = _mockFlowId
						, label            = translatedLabel
						, is_singleton     = true
						, is_admin_flow    = false
						, hide_from_widget = false
					} );

				} );

				it( "should insert a record for each flow step", function(){
					_svc.$( "_getExistingSingletonFlowForStartupCheck" ).$args( _mockFlowId ).$results({} );
					_flowDao.$( "insertData", _mockFlowDbId );
					_stepDao.$( "dataExists", false );

					_svc.initializeSingleton( _mockFlowId );

					expect( _stepDao.$callLog().insertData.len() ).toBe( 5 );
					for( var i=1; i<=5; i++ ) {
						expect( _stepDao.$callLog().insertData[ i ][ 1 ] ).toBe( {
							  webflow = _mockFlowDbId
							, step_id = "step-#i#"
							, sort_order = i
							, site = _siteId
							, position_type = ( i==1 ? "start" : ( i==5 ? "end" : "middle" ) )
						} );
					}
				} );

				it( "should update existing steps with their current/new sortorder and step position type when changed", function(){
					_svc.$( "_getExistingSingletonFlowForStartupCheck" ).$args( _mockFlowId ).$results({} );
					_flowDao.$( "insertData", _mockFlowDbId );
					_stepDao.$( "dataExists", true );

					_svc.$( "_getExistingStepConfigs" ).$args( _mockFlowId ).$results( { "#_siteId#"={
						  "step-1" = { id="step-id-1", step_id="step-1", sort_order=1, position_type="middle" }
						, "step-2" = { id="step-id-2", step_id="step-2", sort_order=2, position_type="middle" }
						, "step-3" = { id="step-id-3", step_id="step-3", sort_order=3, position_type="middle" }
						, "step-4" = { id="step-id-4", step_id="step-4", sort_order=5, position_type="end" }
						, "step-5" = { id="step-id-5", step_id="step-5", sort_order=4, position_type="middle" }
					} } );

					_svc.initializeSingleton( _mockFlowId );

					expect( _stepDao.$callLog().updateData.len() ).toBe( 3 );
					expect( _stepDao.$callLog().updateData[ 1 ] ).toBe( {
						  id            = "step-id-1"
						, data          = { sort_order=1, position_type="start" }
						, bypassTenants = [ "site" ]
					} );
					expect( _stepDao.$callLog().updateData[ 2 ] ).toBe( {
						  id            = "step-id-4"
						, data          = { sort_order=4, position_type="middle" }
						, bypassTenants = [ "site" ]
					} );
					expect( _stepDao.$callLog().updateData[ 3 ] ).toBe( {
						  id            = "step-id-5"
						, data          = { sort_order=5, position_type="end" }
						, bypassTenants = [ "site" ]
					} );
				} );

				it( "should remove any steps that no longer exist", function(){
					_svc.$( "_getExistingSingletonFlowForStartupCheck" ).$args( _mockFlowId ).$results({} );
					_flowDao.$( "insertData", _mockFlowDbId );
					_stepDao.$( "dataExists", true );

					_svc.initializeSingleton( _mockFlowId );
					var stepIds = [];

					for( var step in _mockSteps ) {
						stepIds.append( step.getId() );
					}

					expect( _stepDao.$callLog().deleteData.len() ).toBe( 1 );
					expect( _stepDao.$callLog().deleteData[ 1 ] ).toBe( {
						  filter = "webflow = :webflow and step_id not in (:step_id)"
						, filterParams = { webflow=_mockFlowDbId, step_id=stepIds }
						, bypassTenants = [ "site" ]
					} );
				} );
			} );

			describe( "createConfiguration( webflowId, label, instanceRef, config )", function(){
				beforeEach( function(){
					_setupMockFlow();

					_mockFlowDbId = CreateUUId();
					_mockInstanceRef = CreateUUId();

					_flowDao.$( "selectData" ).$args( filter={ webflow_id=_mockFlowId, instance_ref=_mockInstanceRef } ).$results(
						QueryNew( "id", "varchar", [ [ _mockFlowDbId ] ] )
					);
				} );
				it( "Should create configuration records for the flow + steps", function(){
					var label  = "whatever-" & CreateUUId();
					var config = { this=CreateUUId(), is="config" };

					_svc.$( "_getExistingNonSingletonFlowForStartupCheck", {} );
					_flowDao.$( "insertData", _mockFlowDbId );
					_stepDao.$( "dataExists", false );

					_svc.createConfiguration(
						  webflowId   = _mockFlowId
						, instanceRef = _mockInstanceRef
						, label       = label
						, config      = config
					);

					expect( _flowDao.$callLog().insertData.len() ).toBe( 1 );
					expect( _flowDao.$callLog().insertData[ 1 ][ 1 ] ).toBe( {
						  webflow_id   = _mockFlowId
						, instance_ref = _mockInstanceRef
						, label        = label
						, is_singleton = false
						, config       = SerializeJson( config )
					} );
					expect( _stepDao.$callLog().insertData.len() ).toBe( 5 );
					for( var i=1; i<=5; i++ ) {
						expect( _stepDao.$callLog().insertData[ i ][ 1 ] ).toBe( {
							  webflow = _mockFlowDbId
							, step_id = "step-#i#"
							, sort_order = i
							, site = _siteId
							, position_type = ( i==1 ? "start" : ( i==5 ? "end" : "middle" ) )
						} );
					}
				} );

				it( "Should do nothing when configuration already exists in the database", function(){
					var label  = "whatever-" & CreateUUId();
					var config = { this=CreateUUId(), is="config" };

					_svc.$( "_getExistingNonSingletonFlowForStartupCheck", { weflow_config_hash=CreateUUId()} );
					_svc.$( "_getExistingStepConfigs" ).$args( _mockFlowId, _mockInstanceRef ).$results( { "#_siteId#"={
						  "step-1" = { id="step-id-1", step_id="step-1", sort_order=1, position_type="start" }
						, "step-2" = { id="step-id-2", step_id="step-2", sort_order=2, position_type="middle" }
						, "step-3" = { id="step-id-3", step_id="step-3", sort_order=3, position_type="middle" }
						, "step-4" = { id="step-id-4", step_id="step-4", sort_order=4, position_type="middle" }
						, "step-5" = { id="step-id-5", step_id="step-5", sort_order=5, position_type="end" }
					} } );


					_svc.createConfiguration(
						  webflowId   = _mockFlowId
						, instanceRef = _mockInstanceRef
						, label       = label
						, config      = config
					);

					expect( _flowDao.$callLog().insertData.len() ).toBe( 0 );
					expect( _stepDao.$callLog().insertData.len() ).toBe( 0 );
				} );

				it( "Should raise an informative error when the webflow is a singleton", function(){
					_mockFlow.setSingleton( true );

					expect( function(){
						_svc.createConfiguration(
							  webflowId   = _mockFlowId
							, instanceRef = _mockInstanceRef
							, label       = "blah"
							, config      = {}
						);
					} ).toThrow( "preside.webflow.singleton.flow" );
				} );

			} );

		} );
	}

// helpers
	private void function _setupMockFlow( boolean singleton=false ) {
		_mockFlow   = CreateMock( "preside.system.services.webflow.spec.Webflow" );
		_mockFlowId = CreateUUId();
		_mockTitle  = "My flow #CreateUUId()#";
		_mockSteps  = [];

		for( var i=1; i<=5; i++ ) {
			_mockSteps.append( CreateMock( "preside.system.services.webflow.spec.WebflowStep" ) );
			ArrayLast( _mockSteps ).setId( "step-#i#" );
		}

		_mockFlow.setId( _mockFlowId );
		_mockFlow.setMeta( { title=_mockTitle } );
		_mockFlow.setSteps( _mockSteps );
		_mockFlow.setSingleton( arguments.singleton );

		_webflowLibrary.$( "getWebflow" ).$args( _mockFlowId ).$results( _mockFlow );
	}

}