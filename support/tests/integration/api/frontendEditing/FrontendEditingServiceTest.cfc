component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		var logger        = _getTestLogger();
		var poService     = _getPresideObjectService();
		var draftService  = new preside.system.api.drafts.DraftService( logger = logger, presideObjectService = poService );

		mockPoService = getMockBox().createMock( object=Duplicate( poService ) );

		editingService = new preside.system.api.frontendEditing.FrontendEditingService( logger = logger, presideObjectService = mockPoService, draftService = draftService );
	}

	function beforeTests() {
		_emptyDatabase();
		_dbSync();
		_createDummyUsers();
	}

	function afterTests() {
		_wipeData();
	}

// TESTS
	function test01_saveContent_shouldSaveIndividualFieldToPresideObjectRecord() {
		var expectedUpdateDataCall = {
			  objectName = "meh"
			, data       = { test = "this is test content" }
			, id         = "testid"
		};

		mockPoService.$( "isPageType", false );
		mockPoService.$( "updateData", true );

		editingService.saveContent(
			  object   = expectedUpdateDataCall.objectName
			, property = "test"
			, recordId = expectedUpdateDataCall.id
			, content  = expectedUpdateDataCall.data.test
		);

		var callLog = mockPoService.$callLog().updateData;

		super.assertEquals( 1, callLog.len() );
		super.assertEquals( expectedUpdateDataCall, callLog[1] );
	}

	function test03_draftExists_shouldReturnFalse_whenNoDraftExistsForTheUserAndField(){
		super.assertFalse(
			editingService.draftExists( object="meh", property="test", recordId="testid", owner=testUsers[2].id )
		);
	}

	function test04_draftExists_shouldReturnTrue_whenDraftExistsForUserAndField(){
		editingService.saveDraft(
			  object   = "meh"
			, property = "test"
			, recordId = "testid"
			, content  = "this is test content"
			, owner    = testUsers[3].id
		);

		super.assert(
			editingService.draftExists( object="meh", property="test", recordId="testid", owner=testUsers[3].id )
		);
	}

	function test05_getDraft_shouldReturnSavedDraft(){
		editingService.saveDraft(
			  object   = "meh"
			, property = "test"
			, recordId = "testid"
			, content  = "this is test content"
			, owner    = testUsers[3].id
		);
		editingService.saveDraft(
			  object   = "anotherObj"
			, property = "someOtherProperty"
			, recordId = "someId"
			, content  = "more test content"
			, owner    = testUsers[1].id
		);

		super.assertEquals(
			  "more test content"
			, editingService.getDraft( object="anotherObj", property="someOtherProperty", recordId="someId", owner=testUsers[1].id )
		);
	}

	function test06_discardDraft_shouldDiscardSavedDraft(){
		editingService.saveDraft(
			  object   = "meh"
			, property = "test"
			, recordId = "testid"
			, content  = "this is test content"
			, owner    = testUsers[3].id
		);

		super.assert( editingService.draftExists( object="meh", property="test", recordId="testid", owner=testUsers[3].id ) );

		editingService.discardDraft( object="meh", property="test", recordId="testid", owner=testUsers[3].id );

		super.assertFalse( editingService.draftExists( object="meh", property="test", recordId="testid", owner=testUsers[3].id ) );
	}

// PRIVATE HELPERS
	private function _wipeData() {
	}

	private function _createDummyUsers() {
		variables.testUsers = [
			  { loginId="fred"    , pw="some%$p45%word" , name="Big Daddy"   , email="test1@test.com", id="" }
			, { loginId="james"   , pw="aN0THERP4$$word", name="007"         , email="test2@test.com", id="" }
			, { loginId="boris"   , pw="j0ns0n"         , name="Bendy Boris" , email="test3@test.com", id="" }
			, { loginId="pixl8"   , pw="1nter4ct!ve"    , name="Pixl8"       , email="test4@test.com", id="" }
			, { loginId="mandy"   , pw="sdfjlsdf84£rjs" , name="Patinkin"    , email="test5@test.com", id="" }
			, { loginId="sysadmin", pw="ajdlfjasfas&&^" , name="System Admin", email="test6@test.com", id="" }
		];
		for( var user in testUsers ){
			user.id = _insertData( objectName="security_user", data={ label=user.name, login_id=user.loginId, password=_bCryptPassword( user.pw ), email_address=user.email } );
		}
	}
}