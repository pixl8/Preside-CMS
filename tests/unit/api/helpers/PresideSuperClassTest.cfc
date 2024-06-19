component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "$slugify()", function(){
			it( "should slugify normalize input, making lower case and replacing non a-z1-9 chars with dashes", function(){
				expect( _getSuperClass().$slugify( "This  si_sluf123  Shold be doable!" ) ).toBe( "this-sisluf123-shold-be-doable" );
			} );

			it( "should replace various special characters with simple latin equivalents", function() {
				var specials  = [ "á", "à", "â", "ä" , "ã", "å", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ó", "ò", "ô", "ö" , "õ", "ø", "ú", "ù", "û" , "ü", "ñ", "ç", "ß" , "Á", "À", "Â", "Ä" , "Ã", "Å", "É", "È", "Ê", "Ë", "Í", "Ì", "Î", "Ï", "Ó", "Ò", "Ô", "Ö" , "Õ", "Ø", "Ú", "Ù", "Û", "Ü" , "Ñ", "Ç" ];
				var slugified = [ "a", "a", "a", "ae", "a", "a", "e", "e", "e", "e", "i", "i", "i", "i", "o", "o", "o", "oe", "o", "o", "u", "u", "ue", "u", "n", "c", "ss", "A", "A", "A", "Ae", "A", "A", "E", "E", "E", "E", "I", "I", "I", "I", "O", "O", "O", "Oe", "O", "O", "U", "U", "U", "Ue", "N", "C" ];

				expect( _getSuperClass().$slugify( str=ArrayToList( specials, "" ), preserveCase=true ) ).toBeWithCase( ArrayToList( slugified, "" ) );
			} );
		} );
	}

	function _getSuperClass() {
		return new preside.system.services.PresideSuperClass(
			  presideObjectService       = createStub()
			, systemConfigurationService = createStub()
			, adminLoginService          = createStub()
			, adminPermissionService     = createStub()
			, websiteLoginService        = createStub()
			, websiteUserActionService   = createStub()
			, websitePermissionService   = createStub()
			, emailService               = createStub()
			, errorLogService            = createStub()
			, systemAlertsService        = createStub()
			, featureService             = createStub()
			, notificationService        = createStub()
			, auditService               = createStub()
			, contentRendererService     = createStub()
			, taskmanagerService         = createStub()
			, validationEngine           = createStub()
			, adHocTaskManagerService    = createStub()
			, threadUtil                 = createStub()
			, coldbox                    = createStub()
			, i18n                       = createStub()
			, htmlHelper                 = createStub()
			, healthcheckService         = createStub()
			, sqlRunner                  = createStub()
			, extensionManagerService    = createStub()
			, presideHelperClass         = createStub()
		);
	}

}