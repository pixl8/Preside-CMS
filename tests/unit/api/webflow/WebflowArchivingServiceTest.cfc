component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "archiveExpiredWebflows()", function(){

			beforeEach( function(){
				_library     = CreateStub();
				_confService = CreateStub();
				_storage     = CreateStub();
				_instanceDao = CreateStub();
				_svc         = CreateMock( object=new preside.system.services.webflow.WebflowArchivingService(
					  webflowLibrary              = _library
					, webflowConfigurationService = _confService
					, cfFlowPresideStorage        = _storage
				) );

				_svc.$( "$getPresideObject" ).$args( "cfflow_workflow_instance" ).$results( _instanceDao );
				_storage.$( "archiveInstance" );
			} );

			it( "should skip webflows that do not have an expiry configured", function(){
				_library.$( "getAllWebflows", { noExpiry={} } );
				_confService.$( "getFlowConfig" ).$args( "noExpiry" ).$results( { timeout_in_minutes=0 } );
				_instanceDao.$( "selectData", QueryNew( "owner,reference,sub_reference,sub_sub_reference,completed" ) );

				expect( _svc.archiveExpiredWebflows() ).toBeTrue();
				expect( _instanceDao.$callLog().selectData.len() ).toBe( 0 );
				expect( _storage.$callLog().archiveInstance.len() ).toBe( 0 );
			} );

			it( "should archive expired instances, using 'complete' or 'timedout' as the reason", function(){
				var instances = QueryNew( "owner,reference,sub_reference,sub_sub_reference,completed", "varchar,varchar,varchar,varchar,bit", [
					  [ "o1", "r1", "s1", "ss1", true  ]
					, [ "o2", "r2", "s2", "ss2", false ]
				] );
				_library.$( "getAllWebflows", { myFlow={} } );
				_confService.$( "getFlowConfig" ).$args( "myFlow" ).$results( { timeout_in_minutes=60 } );
				_instanceDao.$( "selectData", instances );

				expect( _svc.archiveExpiredWebflows() ).toBeTrue();

				var calls = _storage.$callLog().archiveInstance;
				expect( calls.len() ).toBe( 2 );
				expect( calls[ 1 ].workflowId    ).toBe( "preside.webflow.myFlow" );
				expect( calls[ 1 ].archiveReason ).toBe( "complete" );
				expect( calls[ 1 ].instanceArgs  ).toBe( { owner="o1", reference="r1", subreference="s1", subSubReference="ss1" } );
				expect( calls[ 2 ].archiveReason ).toBe( "timedout" );
			} );

			it( "should only query for instances modified before the expiry plus one day", function(){
				_library.$( "getAllWebflows", { myFlow={} } );
				_confService.$( "getFlowConfig" ).$args( "myFlow" ).$results( { timeout_in_minutes=60 } );
				_instanceDao.$( "selectData", QueryNew( "owner,reference,sub_reference,sub_sub_reference,completed" ) );

				_svc.archiveExpiredWebflows();

				var params     = _instanceDao.$callLog().selectData[ 1 ].filterParams;
				var expected   = DateAdd( "n", -( 60 + 1440 ), Now() );
				expect( params.workflow_id ).toBe( "preside.webflow.myFlow" );
				expect( Abs( DateDiff( "s", params.datemodified, expected ) ) < 30 ).toBeTrue();
			} );

		} );
	}

}
