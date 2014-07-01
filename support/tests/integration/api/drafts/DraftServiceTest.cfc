component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function beforeTests() {
		presideObjectService = _getPresideObjectService( forceNewInstance=true );
		_emptyDatabase();
		_dbSync();
		_createDummyUsers();
	}

	function afterTests() {
		_wipeData();
	}

	function setup() {
		super.setup();

		draftSvc = new preside.system.services.drafts.DraftService( dao = presideObjectService.getObject( "draft" ) );
	}

// TESTS
	function test01_draftExists_shouldReturnFalse_whenDraftDoesNotExist(){
		super.assertFalse( draftSvc.draftExists(
			  owner = testUsers[3].id
			, key   = "idonotexist"
		) );
	}

	function test02_draftExists_shouldReturnTrue_whenDraftExists(){
		draftSvc.saveDraft(
			  owner   = testUsers[5].id
			, key     = "mykey"
			, content = { test="content" }
		);

		super.assert( draftSvc.draftExists(
			  owner = testUsers[5].id
			, key   = "mykey"
		) );
	}

	function test03_draftExists_shouldReturnFalse_whenDraftExistsButForADifferentUser(){
		draftSvc.saveDraft(
			  owner   = testUsers[2].id
			, key     = "somekey"
			, content = "some draft content"
		);

		super.assertFalse( draftSvc.draftExists(
			  owner = testUsers[3].id
			, key   = "somekey"
		) );
	};

	function test04_getDraftContent_shouldReturnSavedDraftContent(){
		var testContent     = { test="content", withanarray=[1,2,3,{ andaboolean=true, another=false } ] };
		var returnedContent = "";

		draftSvc.saveDraft(
			  owner   = testUsers[1].id
			, key     = "thisisatestkey"
			, content = testContent
		);

		returnedContent = draftSvc.getDraftContent(
			  owner = testUsers[1].id
			, key   = "thisisatestkey"
		);

		super.assertEquals( testContent, returnedContent );
	}

	function test05_getDraftContent_shouldReturnEmptyString_whenDraftDoesNotExist(){
		super.assertEquals( "", draftSvc.getDraftContent(
			  owner = testUsers[3].id
			, key   = "idonotexistinit"
		) );
	}

	function test06_saveDraft_shouldOnlyAllowASingleDraftPerUserAndKeyCombination(){
		var i       = 1;
		var records = "";

		for( i=1; i lte 10; i++ ) {
			draftSvc.saveDraft(
				  owner   = testUsers[3].id
				, key     = "thisisatestkey"
				, content = "some content #i#"
			);
		}

		records = _selectData( objectName="draft", filter={ owner=testUsers[3].id, key="thisisatestkey" } );
		super.assertEquals( 1, records.recordCount );
		super.assertEquals( "some content 10", draftSvc.getDraftContent( owner=testUsers[3].id, key="thisisatestkey" ) );
	}

	function test07_discardDraft_shouldDeleteDraftRecordForUserAndKeyCombination(){
		var records = "";

		draftSvc.saveDraft(
			  owner   = testUsers[3].id
			, key     = "thisisatestkey"
			, content = "some content"
		);
		draftSvc.saveDraft(
			  owner   = testUsers[3].id
			, key     = "anotherkey"
			, content = "some other content"
		);
		draftSvc.saveDraft(
			  owner   = testUsers[2].id
			, key     = "thisisatestkey"
			, content = "some more content"
		);

		records = _selectData( objectName="draft", filter={ key="thisisatestkey" }, useCache=false );
		super.assertEquals( 2, records.recordCount, "test borked" );

		draftSvc.discardDraft(
			  owner   = testUsers[3].id
			, key     = "thisisatestkey"
		);

		records = _selectData( objectName="draft", filter={ key="thisisatestkey" }, useCache=false );
		super.assertEquals( 1, records.recordCount );
		super.assertEquals( testUsers[2].id, records.owner );

		records = _selectData( objectName="draft", filter={ owner = testUsers[3].id }, useCache=false );
		super.assertEquals( 1, records.recordCount );
		super.assertEquals( "anotherkey", records.key );
	}

// PRIVATE HELPERS
	private function _wipeData() {
		_deleteData( objectName="draft", forceDeleteAll=true );
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