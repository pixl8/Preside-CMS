component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow actions service", function() {

			beforeEach( function(){
				_svc = CreateMock( object=new preside.system.services.webflow.WebflowActionsService() );
				_instance = CreateMock( object=new cfflow.models.instances.WorkflowInstance() );
				_nextAction = "next";
				_prevAction = "prev";
			} );

			describe( "hasNextAction( instance )", function(){
				it( "should return true when the instance has a manual action with the id 'next'", function(){
					_instance.$( "getManualActions", [ _prevAction, _nextAction ] );

					expect( _svc.hasNextAction( _instance ) ).toBe( true );

					_instance.$( "getManualActions", [ _nextAction ] );

					expect( _svc.hasNextAction( _instance ) ).toBe( true );
				} );

				it( "should return false when the instance has no actions with the id 'next'", function(){
					_instance.$( "getManualActions", [ _prevAction ] );

					expect( _svc.hasNextAction( _instance ) ).toBe( false );

					_instance.$( "getManualActions", [] );

					expect( _svc.hasNextAction( _instance ) ).toBe( false );
				} );
			} );

			describe( "hasPrevAction( instance )", function(){
				it( "should return true when the instance has a manual action with the id 'prev'", function(){
					_instance.$( "getManualActions", [ _prevAction, _nextAction ] );

					expect( _svc.hasPrevAction( _instance ) ).toBe( true );

					_instance.$( "getManualActions", [ _prevAction ] );

					expect( _svc.hasPrevAction( _instance ) ).toBe( true );
				} );

				it( "should return false when the instance has no actions with the id 'prev'", function(){
					_instance.$( "getManualActions", [ _nextAction ] );

					expect( _svc.hasPrevAction( _instance ) ).toBe( false );

					_instance.$( "getManualActions", [] );

					expect( _svc.hasPrevAction( _instance ) ).toBe( false );
				} );
			} );

		} );
	}

}