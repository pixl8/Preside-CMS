component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "applyUserColumns()", function(){
			it( "should keep locked fields first and drop fields that are not available", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "crm_contact" ).$results( [ "label" ] );

				var result = svc.applyUserColumns(
					  objectName    = "crm_contact"
					, defaultFields = [ "label", "email" ]
					, available     = [ "label", "email", "datemodified" ]
					, storedFields  = [ "email", "hacked", "datemodified" ]
				);

				expect( result ).toBe( [ "label", "email", "datemodified" ] );
			} );

			it( "should use default fields when no stored preference exists", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "crm_contact" ).$results( [ "label" ] );

				var result = svc.applyUserColumns(
					  objectName    = "crm_contact"
					, defaultFields = [ "label", "email" ]
					, available     = [ "label", "email", "phone" ]
					, storedFields  = []
				);

				expect( result ).toBe( [ "label", "email" ] );
			} );

			it( "should persist the supplied columns rather than the previously stored preference", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "crm_contact" ).$results( [ "label" ] );

				var result = svc.applyUserColumns(
					  objectName    = "crm_contact"
					, defaultFields = [ "label", "email" ]
					, available     = [ "label", "email", "phone" ]
					, storedFields  = [ "label", "phone" ]
				);

				expect( result ).toBe( [ "label", "phone" ] );
			} );

			it( "should not force the label column when no fields are locked", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "crm_contact" ).$results( [] );

				var result = svc.applyUserColumns(
					  objectName    = "crm_contact"
					, defaultFields = [ "label", "email" ]
					, available     = [ "label", "email", "phone" ]
					, storedFields  = [ "email", "phone" ]
				);

				expect( result ).toBe( [ "email", "phone" ] );
			} );
		} );

		describe( "resolveListingContext()", function(){
			it( "should use the datasource query string, drop cache-busters and sort remaining pairs", function(){
				var svc = _getService();

				expect( svc.resolveListingContext(
					datasourceUrl = "/admin/datamanager/getObjectRecordsForAjaxDataTables/?product=abc&id=crm_subscription&cachebuster=1&prefetchCacheBuster=2&_=3"
				) ).toBe( {
					  key   = "id=crm_subscription&product=abc"
					, label = ""
					, named = false
				} );
			} );

			it( "should treat a datasource URL with no remaining query string as an empty context", function(){
				var svc = _getService();

				expect( svc.resolveListingContext(
					datasourceUrl = "/admin/datamanager/getObjectRecordsForAjaxDataTables/"
				) ).toBe( {
					  key   = ""
					, label = ""
					, named = false
				} );
			} );

			it( "should prefer a developer-supplied context key and translate a labelled i18n URI", function(){
				var svc = _getService();

				svc.$( "$translateResource" ).$args(
					  uri          = "crm.subscription:listing.context.corporate"
					, defaultValue = "crm.subscription:listing.context.corporate"
				).$results( "Corporate subscriptions" );

				expect( svc.resolveListingContext(
					  listingContextKey   = "corporate"
					, listingContextLabel = "crm.subscription:listing.context.corporate"
					, datasourceUrl       = "/admin/datamanager/getObjectRecordsForAjaxDataTables/?id=crm_subscription&product=abc"
				) ).toBe( {
					  key   = "corporate"
					, label = "Corporate subscriptions"
					, named = true
				} );
			} );

			it( "should keep an already-translated context label", function(){
				var svc = _getService();

				expect( svc.resolveListingContext(
					  listingContextKey   = "corporate"
					, listingContextLabel = "Corporate subscriptions"
				) ).toBe( {
					  key   = "corporate"
					, label = "Corporate subscriptions"
					, named = true
				} );
			} );

			it( "should hash context keys longer than 100 characters", function(){
				var svc     = _getService();
				var longKey = RepeatString( "a", 101 );

				expect( svc.resolveListingContext( listingContextKey=longKey ).key ).toBe( LCase( Hash( longKey ) ) );
			} );
		} );

		describe( "getUserPreference()", function(){
			it( "should read columns and active view for the current listing context", function(){
				var svc     = _getService();
				var mockDao = createStub();
				var record  = QueryNew( "id,columns,active_view", "varchar,varchar,varchar", [
					[ "pref-1", "label,notes", "view-9" ]
				] );

				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.$( "$getPresideObject" ).$args( "admin_datatable_user_preference" ).$results( mockDao );
				mockDao.$( "selectData", record );

				var pref = svc.getUserPreference(
					  objectName = "crm_subscription"
					, listingKey = "crm_subscription"
					, contextKey = "product=abc"
				);

				expect( pref.columns ).toBe( [ "label", "notes" ] );
				expect( pref.activeView ).toBe( "view-9" );
				expect( mockDao.$callLog().selectData[ 1 ].filter.context_key ).toBe( "product=abc" );
			} );
		} );

		describe( "listAvailableColumns()", function(){
			it( "should merge explicitly passed columns with annotated grid fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "email_template" ).$results( [ "name", "datecreated", "datemodified" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "email_template" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "email_template" ).$results( [] );
				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getIdField", "id" );
				mockPoService.$( "getObjectProperties", {
					  name           = { name="name" }
					, datecreated    = { name="datecreated" }
					, datemodified   = { name="datemodified" }
					, sending_method = { name="sending_method" }
					, open_rate      = { name="open_rate" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns(
					  objectName  = "email_template"
					, extraFields = [ "name", "sending_method", "open_rate" ]
				);

				expect( ArrayFindNoCase( result, "name" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "datecreated" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "sending_method" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "open_rate" ) ).toBeGT( 0 );
			} );

			it( "should expand wildcard picker fields and drop named exclusions", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label", "status" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "my_extension_object"
					, attributeName = "datamanagerColumnPickerFields"
					, defaultValue  = ""
				).$results( "*,!sensitive_col,!other_sensitive_col" );
				mockPoService.$( "getObjectProperties", {
					  label               = { name="label" }
					, status              = { name="status" }
					, notes               = { name="notes" }
					, datemodified        = { name="datemodified" }
					, sensitive_col       = { name="sensitive_col" }
					, other_sensitive_col = { name="other_sensitive_col" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "notes" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "datemodified" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "sensitive_col" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "other_sensitive_col" ) ).toBe( 0 );
			} );

			it( "should match glob exclusions in picker fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "my_extension_object"
					, attributeName = "datamanagerColumnPickerFields"
					, defaultValue  = ""
				).$results( "*,!*_col" );
				mockPoService.$( "getObjectProperties", {
					  label               = { name="label" }
					, notes               = { name="notes" }
					, sensitive_col       = { name="sensitive_col" }
					, other_sensitive_col = { name="other_sensitive_col" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "notes" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "sensitive_col" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "other_sensitive_col" ) ).toBe( 0 );
			} );

			it( "should use the global column picker default when the object has no picker annotation", function(){
				var svc           = _getService( { columnPickerFields="*" } );
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getObjectProperties", {
					  label         = { name="label" }
					, notes         = { name="notes" }
					, datemodified  = { name="datemodified" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "notes" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "datemodified" ) ).toBeGT( 0 );
			} );

			it( "should default to auto picker fields when the object has no picker annotation", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getIdField", "id" );
				mockPoService.$( "getObjectProperties", {
					  id     = { name="id", type="string", dbtype="varchar" }
					, label  = { name="label", type="string", dbtype="varchar" }
					, email  = { name="email", type="string", dbtype="varchar" }
					, notes  = { name="notes", type="string", dbtype="longtext" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "email" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "id" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "notes" ) ).toBe( 0 );
			} );

			it( "should expand auto picker fields using sensible exclusions", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "my_extension_object"
					, attributeName = "datamanagerColumnPickerFields"
					, defaultValue  = ""
				).$results( "auto" );
				mockPoService.$( "getIdField", "id" );
				mockPoService.$( "getObjectProperties", {
					  id           = { name="id", type="string", dbtype="varchar" }
					, label        = { name="label", type="string", dbtype="varchar" }
					, email        = { name="email", type="string", dbtype="varchar" }
					, organisation = { name="organisation", type="string", relationship="many-to-one", relatedTo="crm_organisation" }
					, post_count   = { name="post_count", type="numeric", formula="Count( ${prefix}posts.id )" }
					, bio          = { name="bio", type="string", dbtype="text" }
					, notes        = { name="notes", type="string", dbtype="longtext" }
					, internal     = { name="internal", type="string", dbtype="varchar", excludeDataExport=true }
					, hidden_flag  = { name="hidden_flag", type="boolean", autofilter=false }
					, contacts     = { name="contacts", relationship="one-to-many" }
					, tags         = { name="tags", relationship="many-to-many" }
					, data_view    = { name="data_view", relationship="select-data-view" }
					, _internal    = { name="_internal", type="string", dbtype="varchar" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "id" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "label" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "email" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "organisation" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "post_count" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "bio" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "notes" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "internal" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "hidden_flag" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "contacts" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "tags" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "data_view" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "_internal" ) ).toBe( 0 );
			} );

			it( "should keep annotated grid fields in the auto picker pool even when they fail auto rules", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label", "notes" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [ "bio" ] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "my_extension_object"
					, attributeName = "datamanagerColumnPickerFields"
					, defaultValue  = ""
				).$results( "auto" );
				mockPoService.$( "getIdField", "id" );
				mockPoService.$( "getObjectProperties", {
					  label = { name="label", type="string", dbtype="varchar" }
					, notes = { name="notes", type="string", dbtype="longtext" }
					, bio   = { name="bio", type="string", dbtype="text" }
					, email = { name="email", type="string", dbtype="varchar" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "notes" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "bio" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "email" ) ).toBeGT( 0 );
			} );

			it( "should honour datamanagerUserColumn opt-in and exclusions with auto picker fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				variables.mockDataManager.$( "listGridFields" ).$args( "my_extension_object" ).$results( [ "label" ] );
				variables.mockDataManager.$( "listHiddenGridFields" ).$args( "my_extension_object" ).$results( [] );
				variables.mockDataManager.$( "listSearchFields" ).$args( "my_extension_object" ).$results( [] );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "my_extension_object"
					, attributeName = "datamanagerColumnPickerFields"
					, defaultValue  = ""
				).$results( "auto,!email" );
				mockPoService.$( "getIdField", "id" );
				mockPoService.$( "getObjectProperties", {
					  label        = { name="label", type="string", dbtype="varchar" }
					, email        = { name="email", type="string", dbtype="varchar" }
					, notes        = { name="notes", type="string", dbtype="longtext", datamanagerUserColumn=true }
					, hidden_flag  = { name="hidden_flag", type="boolean", autofilter=false, datamanagerUserColumn=true }
					, status       = { name="status", type="string", dbtype="varchar", datamanagerUserColumn=false }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				var result = svc.listAvailableColumns( objectName="my_extension_object" );

				expect( ArrayFindNoCase( result, "notes" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "hidden_flag" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( result, "email" ) ).toBe( 0 );
				expect( ArrayFindNoCase( result, "status" ) ).toBe( 0 );
			} );
		} );

		describe( "listLockedColumns()", function(){
			it( "should return no locked columns when the object has no locked-fields annotation", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				mockPoService.$( "getObjectAttribute", "" );
				svc.$( "$getPresideObjectService", mockPoService );

				expect( svc.listLockedColumns( "crm_contact" ) ).toBe( [] );
			} );

			it( "should return annotated locked fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "crm_contact"
					, attributeName = "datamanagerLockedGridFields"
					, defaultValue  = ""
				).$results( "label, status" );
				svc.$( "$getPresideObjectService", mockPoService );

				expect( svc.listLockedColumns( "crm_contact" ) ).toBe( [ "label", "status" ] );
			} );
		} );

		describe( "listQuickFilters()", function(){
			it( "should offer filters for available listing columns and skip formula fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();
				var filters       = [];
				var byField       = {};
				var filter        = {};

				svc.$( "listAvailableColumns", [ "label", "notes", "organisation", "post_count" ] );
				svc.$( "$translatePropertyName", "Label" );
				svc.$( "$translateResource", "Organisations" );

				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getResourceBundleUriRoot", "preside-objects.crm_organisation:" );
				mockPoService.$( "getObjectProperties", {
					  label        = { name="label", type="string" }
					, notes        = { name="notes", type="string" }
					, organisation = { name="organisation", type="string", relationship="many-to-one", relatedTo="crm_organisation" }
					, post_count   = { name="post_count", type="numeric", formula="Count( ${prefix}posts.id )" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				filters = svc.listQuickFilters( "my_extension_object" );
				for( filter in filters ) {
					byField[ filter.field ] = filter;
				}

				expect( StructKeyExists( byField, "label" ) ).toBeTrue();
				expect( StructKeyExists( byField, "notes" ) ).toBeTrue();
				expect( StructKeyExists( byField, "post_count" ) ).toBeFalse();
				expect( byField.organisation.type ).toBe( "object" );
				expect( byField.organisation.relatedTo ).toBe( "crm_organisation" );
				expect( byField.organisation.expressionId ).toBe( "presideobject_manytoonematch_my_extension_object.organisation" );
				expect( byField.organisation.filterExpressionId ).toBe( "presideobject_manytoonefilter_my_extension_object.organisation" );
			} );

			it( "should honour getListingQuickFilterFields customization", function(){
				var svc           = _getService();
				var mockPoService = createStub();
				var filters       = [];

				variables.mockCustomization.$( method="runCustomization", callback=function(){
					if ( ( arguments.action ?: "" ) == "getListingQuickFilterFields" ) {
						return [ "notes" ];
					}
					return "";
				} );
				svc.$( "$translatePropertyName", "Notes" );
				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getObjectProperties", {
					  label = { name="label", type="string" }
					, notes = { name="notes", type="string" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				filters = svc.listQuickFilters( "my_extension_object" );

				expect( filters.len() ).toBe( 1 );
				expect( filters[ 1 ].field ).toBe( "notes" );
			} );

			it( "should emit formula quick filters for autofilter custom fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();
				var filters       = [];
				var byField       = {};
				var filter        = {};

				svc.$( "listAvailableColumns", [ "nickname", "gallery_count" ] );
				svc.$( "$translatePropertyName", "Nickname" );
				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getObjectProperties", {
					  nickname      = { name="nickname", type="string", formula="( select 1 )", customField=true, autofilter=true, customFieldDataType="text" }
					, gallery_count = { name="gallery_count", type="numeric", formula="count( 1 )", customField=true, autofilter=true, customFieldKind="aggregate" }
				} );
				svc.$( "$getPresideObjectService", mockPoService );

				filters = svc.listQuickFilters( "elf_test_object" );
				for( filter in filters ) {
					byField[ filter.field ] = filter;
				}

				expect( byField.nickname.type ).toBe( "text" );
				expect( byField.nickname.expressionId ).toBe( "presideobject_formulamatches_elf_test_object.nickname" );
				expect( byField.gallery_count.type ).toBe( "numeric" );
				expect( byField.gallery_count.expressionId ).toBe( "presideobject_formulacompares_elf_test_object.gallery_count" );
			} );

			it( "should emit conditional-label options for filterable custom fields", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				svc.$( "listAvailableColumns", [ "status_label" ] );
				svc.$( "$translatePropertyName", "Status" );
				mockPoService.$( "getObjectAttribute", "" );
				mockPoService.$( "getObjectProperties", {
					status_label = { name="status_label", type="string", formula="concat( 15, '.', id )", customField=true, customFieldId=15, customFieldKind="conditional_label", autofilter=true }
				} );
				svc.$( "$getPresideObjectService", mockPoService );
				variables.mockCustomFields.$( "listConditionalRuleOptions" ).$args( 15 ).$results( [
					  { id="rule-1", label="Red" }
					, { id="rule-2", label="Blue" }
				] );

				var filters = svc.listQuickFilters( "elf_test_object" );

				expect( filters.len() ).toBe( 1 );
				expect( filters[ 1 ].type ).toBe( "enum" );
				expect( filters[ 1 ].expressionId ).toBe( "presideobject_conditionallabelmatches_elf_test_object.status_label" );
				expect( filters[ 1 ].options ).toBe( [
					  { id="rule-1", label="Red" }
					, { id="rule-2", label="Blue" }
				] );
			} );
		} );

		describe( "listingAllowsSavedViews()", function(){
			it( "should default to the column picker flag when the object has no saved-views annotation", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				mockPoService.$( "getObjectAttribute", "" );
				svc.$( "$getPresideObjectService", mockPoService );

				expect( svc.listingAllowsSavedViews( objectName="crm_contact", allowColumnPicker=true ) ).toBeTrue();
				expect( svc.listingAllowsSavedViews( objectName="crm_contact", allowColumnPicker=false ) ).toBeFalse();
			} );

			it( "should honour an explicit object annotation over the column picker flag", function(){
				var svc           = _getService();
				var mockPoService = createStub();

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = "crm_contact"
					, attributeName = "datamanagerAllowSavedViews"
					, defaultValue  = ""
				).$results( false );
				svc.$( "$getPresideObjectService", mockPoService );

				expect( svc.listingAllowsSavedViews( objectName="crm_contact", allowColumnPicker=true ) ).toBeFalse();
			} );

			it( "should stay off for compact listings even when columns can be edited", function(){
				var svc = _getService();

				expect( svc.listingAllowsSavedViews(
					  objectName        = "crm_contact"
					, allowColumnPicker = true
					, compact           = true
					, allowSavedViews   = true
				) ).toBeFalse();
			} );

			it( "should honour an explicit listing flag", function(){
				var svc = _getService();

				expect( svc.listingAllowsSavedViews(
					  objectName        = "crm_contact"
					, allowColumnPicker = true
					, allowSavedViews   = false
				) ).toBeFalse();
			} );
		} );

		describe( "mergeExpressionArrays()", function(){
			it( "should AND two expression arrays together", function(){
				var svc    = _getService();
				var left   = [ { expression="a", fields={} } ];
				var right  = [ { expression="b", fields={} } ];
				var merged = svc.mergeExpressionArrays( left, right );

				expect( merged.len() ).toBe( 3 );
				expect( merged[ 2 ] ).toBe( "and" );
				expect( merged[ 1 ].expression ).toBe( "a" );
				expect( merged[ 3 ].expression ).toBe( "b" );
			} );

			it( "should return the non-empty side when the other is empty", function(){
				var svc = _getService();

				expect( svc.mergeExpressionArrays( [], [ { expression="b" } ] ) ).toBe( [ { expression="b" } ] );
				expect( svc.mergeExpressionArrays( [ { expression="a" } ], [] ) ).toBe( [ { expression="a" } ] );
			} );
		} );

		describe( "filterRequestedGridFields()", function(){
			it( "should drop fields that are not in the granted listing pool", function(){
				var svc = _getService();

				expect( svc.filterRequestedGridFields(
					  requestedFields = [ "label", "notes", "sensitive_col" ]
					, grantedColumns  = [ "label", "status", "notes" ]
					, defaultFields   = [ "label", "status" ]
				) ).toBe( [ "label", "notes" ] );
			} );

			it( "should fall back to granted default fields when the request is empty or fully rejected", function(){
				var svc = _getService();

				expect( svc.filterRequestedGridFields(
					  requestedFields = [ "sensitive_col" ]
					, grantedColumns  = [ "label", "status", "notes" ]
					, defaultFields   = [ "label", "status" ]
				) ).toBe( [ "label", "status" ] );
			} );
		} );

		describe( "getGrantedListingColumns()", function(){
			it( "should ignore an unsigned extra column list and keep picker exclusions", function(){
				var svc = _getService();

				svc.$( "listAvailableColumns" ).$args( objectName="my_extension_object" ).$results( [ "label", "notes" ] );
				svc.$( "verifyGrantedColumns", false );

				expect( svc.getGrantedListingColumns(
					  objectName       = "my_extension_object"
					, grantedFields    = [ "label", "notes", "sensitive_col" ]
					, grantedFieldsSig = "forged"
				) ).toBe( [ "label", "notes" ] );
			} );

			it( "should merge a signed extra column list into the available pool", function(){
				var svc = _getService();

				svc.$( "verifyGrantedColumns", true );
				svc.$( "listAvailableColumns" ).$args(
					  objectName  = "email_template"
					, extraFields = [ "name", "sending_method" ]
				).$results( [ "name", "datecreated", "sending_method" ] );

				expect( svc.getGrantedListingColumns(
					  objectName       = "email_template"
					, listingKey       = "email_template"
					, grantedFields    = [ "name", "sending_method" ]
					, grantedFieldsSig = "valid"
				) ).toBe( [ "name", "datecreated", "sending_method" ] );
			} );
		} );

		describe( "signGrantedColumns()", function(){
			it( "should verify a signature for the same object, listing and columns", function(){
				var svc     = _getService();
				var columns = [ "notes", "label" ];
				var sig     = svc.signGrantedColumns( "my_extension_object", "my_extension_object", columns );

				expect( svc.verifyGrantedColumns( "my_extension_object", "my_extension_object", columns, sig ) ).toBeTrue();
				expect( svc.verifyGrantedColumns( "my_extension_object", "my_extension_object", [ "label", "sensitive_col" ], sig ) ).toBeFalse();
			} );
		} );

		describe( "sanitizeViewColumns()", function(){
			it( "should drop columns that are not in the granted listing pool", function(){
				var svc = _getService();

				expect( svc.sanitizeViewColumns(
					  columns        = [ "label", "notes", "sensitive_col" ]
					, grantedColumns = [ "label", "status", "notes" ]
				) ).toBe( [ "label", "notes" ] );
			} );

			it( "should keep locked columns first when an object name is supplied", function(){
				var svc = _getService();

				svc.$( "listLockedColumns" ).$args( "my_extension_object" ).$results( [ "label" ] );

				expect( svc.sanitizeViewColumns(
					  columns        = [ "notes", "status" ]
					, grantedColumns = [ "label", "status", "notes" ]
					, objectName     = "my_extension_object"
				) ).toBe( [ "label", "notes", "status" ] );
			} );
		} );

		describe( "sanitizeFilterState()", function(){
			it( "should drop saved filter IDs the current user cannot use", function(){
				var svc = _getService();

				expect( svc.sanitizeFilterState(
					  filterState        = { savedFilterIds=[ "keep-me", "drop-me" ], advancedFilter=[], columnSearch={} }
					, permittedFilterIds = [ "keep-me" ]
				).savedFilterIds ).toBe( [ "keep-me" ] );
			} );

			it( "should drop column searches for fields that are not granted", function(){
				var svc   = _getService();
				var state = svc.sanitizeFilterState(
					  filterState     = {
						  savedFilterIds = []
						, advancedFilter = []
						, columnSearch   = {
							  status        = { search={ logic="equal", value="active" } }
							, sensitive_col = { search={ logic="contains", value="secret" } }
						  }
					  }
					, grantedColumns  = [ "label", "status" ]
				);

				expect( StructKeyExists( state.columnSearch, "status" ) ).toBeTrue();
				expect( StructKeyExists( state.columnSearch, "sensitive_col" ) ).toBeFalse();
			} );
		} );

		describe( "viewStatesEqual()", function(){
			it( "should treat the implicit default as empty filters plus the supplied columns", function(){
				var svc     = _getService();
				var columns = [ "label", "status" ];
				var named   = {
					  columns     = columns
					, filterState = { savedFilterIds=[ "starred" ], advancedFilter=[], columnSearch={} }
				};

				expect( svc.viewStatesEqual( svc.defaultViewState( columns ), svc.defaultViewState( columns ) ) ).toBeTrue();
				expect( svc.viewStatesEqual( svc.defaultViewState( columns ), named ) ).toBeFalse();
			} );

			it( "should ignore saved filter ID order when comparing", function(){
				var svc = _getService();

				expect( svc.viewStatesEqual(
					  { columns=[ "label" ], filterState={ savedFilterIds=[ "b", "a" ], advancedFilter=[], columnSearch={} } }
					, { columns=[ "label" ], filterState={ savedFilterIds=[ "a", "b" ], advancedFilter=[], columnSearch={} } }
				) ).toBeTrue();
			} );

			it( "should treat sort order as part of the snapshot", function(){
				var svc = _getService();

				expect( svc.viewStatesEqual(
					  { columns=[ "label" ], filterState={ savedFilterIds=[], advancedFilter=[], columnSearch={} }, sort=[ [ "label", "asc" ] ] }
					, { columns=[ "label" ], filterState={ savedFilterIds=[], advancedFilter=[], columnSearch={} }, sort=[ [ "label", "asc" ] ] }
				) ).toBeTrue();
				expect( svc.viewStatesEqual(
					  { columns=[ "label" ], filterState={ savedFilterIds=[], advancedFilter=[], columnSearch={} }, sort=[ [ "label", "asc" ] ] }
					, { columns=[ "label" ], filterState={ savedFilterIds=[], advancedFilter=[], columnSearch={} }, sort=[ [ "label", "desc" ] ] }
				) ).toBeFalse();
			} );
		} );

		describe( "sanitizeSortOrder()", function(){
			it( "should keep granted fields and drop the rest", function(){
				var svc = _getService();

				expect( svc.sanitizeSortOrder(
					  sortOrder       = [ [ "label", "desc" ], [ "secret", "asc" ], [ "status", "ASC" ] ]
					, grantedColumns  = [ "label", "status" ]
				) ).toBe( [ [ "label", "desc" ], [ "status", "asc" ] ] );
			} );

			it( "should accept a JSON array of field/dir pairs", function(){
				var svc = _getService();

				expect( svc.sanitizeSortOrder(
					  sortOrder      = '[["datecreated","desc"]]'
					, grantedColumns = [ "datecreated", "label" ]
				) ).toBe( [ [ "datecreated", "desc" ] ] );
			} );
		} );

		describe( "listEverythingBarActions()", function(){
			it( "should return an empty array when no customization is registered", function(){
				var svc = _getService();

				expect( svc.listEverythingBarActions( "crm_contact" ) ).toBe( [] );
			} );

			it( "should keep valid actions and default icon and requireQuery", function(){
				var svc = _getService();

				variables.mockCustomization.$( "runCustomization", [ {
					  id       = "askAi"
					, labelUri = "readyintelligence:listing.askAi"
					, endpoint = "/admin/readyintelligence/listingAskAi/"
					, icon     = "fa-magic"
				}, {
					  label = "missing id"
				} ] );

				var actions = svc.listEverythingBarActions( "crm_contact" );

				expect( actions.len() ).toBe( 1 );
				expect( actions[ 1 ].id ).toBe( "askAi" );
				expect( actions[ 1 ].icon ).toBe( "magic" );
				expect( actions[ 1 ].requireQuery ).toBeTrue();
				expect( actions[ 1 ].labelUri ).toBe( "readyintelligence:listing.askAi" );
				expect( actions[ 1 ].endpoint ).toBe( "/admin/readyintelligence/listingAskAi/" );
			} );

			it( "should honour requireQuery=false", function(){
				var svc = _getService();

				variables.mockCustomization.$( "runCustomization", [ {
					  id           = "openHelp"
					, requireQuery = false
					, label        = "Help"
				} ] );

				expect( svc.listEverythingBarActions( "crm_contact" )[ 1 ].requireQuery ).toBeFalse();
			} );
		} );

		describe( "listSavedViews()", function(){
			it( "should request owned or shared views for the current listing", function(){
				var svc       = _getService();
				var mockDao   = createStub();
				var mockPerms = createStub();
				var records   = QueryNew( "id,label,owner,is_shared,columns,filter_state", "varchar,varchar,varchar,bit,varchar,varchar", [
					  [ "mine", "My view", "user-1", false, "label,status", "{}" ]
					, [ "ours", "Shared view", "user-2", true, "label", "{}" ]
				] );

				mockPerms.$( "listUserGroups", [] );
				svc.$( "$getAdminPermissionService", mockPerms );
				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.$( "$getPresideObject" ).$args( "admin_datatable_saved_view" ).$results( mockDao );
				svc.$( "getGrantedListingColumns", [ "label", "status" ] );
				svc.$( "listLockedColumns", [ "label" ] );
				mockDao.$( "selectData", records );

				var views = svc.listSavedViews( "my_extension_object" );

				expect( views.len() ).toBe( 2 );
				expect( views[ 1 ].id ).toBe( "mine" );
				expect( views[ 1 ].owner ).toBeTrue();
				expect( views[ 2 ].id ).toBe( "ours" );
				expect( views[ 2 ].owner ).toBeFalse();
				expect( views[ 2 ].shared ).toBeTrue();
				expect( mockDao.$callLog().selectData.len() ).toBe( 1 );
				expect( mockDao.$callLog().selectData[ 1 ].extraFilters[ 1 ].filter ).toInclude( "is_shared" );
			} );
		} );

		describe( "deleteSavedView()", function(){
			it( "should reset user preferences that still point at the deleted view", function(){
				var svc     = _getService();
				var viewDao = createStub();
				var prefDao = createStub();

				svc.$( "_getOwnedSavedView", { id="view-1", label="Mine" } );
				svc.$( "$getPresideObject" ).$args( "admin_datatable_saved_view" ).$results( viewDao );
				svc.$( "$getPresideObject" ).$args( "admin_datatable_user_preference" ).$results( prefDao );
				viewDao.$( "deleteData", 1 );
				prefDao.$( "updateData", 1 );

				expect( svc.deleteSavedView( viewId="view-1", objectName="my_extension_object" ) ).toBeTrue();
				expect( viewDao.$callLog().deleteData[ 1 ].id ).toBe( "view-1" );
				expect( prefDao.$callLog().updateData[ 1 ].filter.active_view ).toBe( "view-1" );
				expect( prefDao.$callLog().updateData[ 1 ].data.active_view ).toBe( "default" );
			} );
		} );

		describe( "resolveDefaultView()", function(){
			it( "should prefer a personal assignment, then the newest group assignment, then everyone", function(){
				var svc       = _getService();
				var mockDao   = createStub();
				var mockPerms = createStub();
				var views     = [
					  { id="view-me"     , label="Mine" }
					, { id="view-group"  , label="Group" }
					, { id="view-all"    , label="Everyone" }
				];

				mockPerms.$( "listUserGroups", [ "group-1" ] );
				svc.$( "$getAdminPermissionService", mockPerms );
				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.$( "listSavedViews", views );
				svc.$( "$getPresideObject" ).$args( "admin_datatable_listing_default" ).$results( mockDao );

				mockDao.$( method="selectData", callback=function(){
					var filter = arguments.filter ?: {};
					if ( ( filter.scope ?: "" ) == "individual" ) {
						return QueryNew( "saved_view", "varchar", [ [ "view-me" ] ] );
					}
					return QueryNew( "saved_view", "varchar" );
				} );

				expect( svc.resolveDefaultView( "my_extension_object" ).id ).toBe( "view-me" );

				mockDao.$( method="selectData", callback=function(){
					var filter = arguments.filter ?: {};
					if ( ( filter.scope ?: "" ) == "group" ) {
						return QueryNew( "saved_view", "varchar", [ [ "view-group" ] ] );
					}
					if ( ( filter.scope ?: "" ) == "global" ) {
						return QueryNew( "saved_view", "varchar", [ [ "view-all" ] ] );
					}
					return QueryNew( "saved_view", "varchar" );
				} );

				expect( svc.resolveDefaultView( "my_extension_object" ).id ).toBe( "view-group" );

				mockDao.$( method="selectData", callback=function(){
					var filter = arguments.filter ?: {};
					if ( ( filter.scope ?: "" ) == "global" ) {
						return QueryNew( "saved_view", "varchar", [ [ "view-all" ] ] );
					}
					return QueryNew( "saved_view", "varchar" );
				} );

				expect( svc.resolveDefaultView( "my_extension_object" ).id ).toBe( "view-all" );
			} );

			it( "should skip assignments the user cannot see and fall back to synthetic default", function(){
				var svc       = _getService();
				var mockDao   = createStub();
				var mockPerms = createStub();

				mockPerms.$( "listUserGroups", [] );
				svc.$( "$getAdminPermissionService", mockPerms );
				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.$( "listSavedViews", [] );
				svc.$( "$getPresideObject" ).$args( "admin_datatable_listing_default" ).$results( mockDao );
				mockDao.$( "selectData", QueryNew( "saved_view", "varchar", [ [ "hidden-view" ] ] ) );

				expect( svc.resolveDefaultView( "my_extension_object" ) ).toBe( {} );
			} );
		} );

		describe( "getToolbarConfig()", function(){
			it( "should expose a resolved default view id without reading it off the function call", function(){
				var svc    = _getService();
				var config = {};

				svc.$( "listAvailableColumns", [ "label" ] );
				svc.$( "getUserPreference", { columns=[ "label" ], activeView="default" } );
				svc.$( "applyUserColumns", [ "label" ] );
				svc.$( "listLockedColumns", [] );
				svc.$( "listQuickFilters", [] );
				svc.$( "listEverythingBarActions", [] );
				svc.$( "listSavedViews", [ { id="view-1", label="Mine" } ] );
				svc.$( "resolveDefaultView", { id="view-1", label="Mine" } );
				svc.$( "getListingDefaultAssignments", { personal="view-1", everyone="", groups=[] } );
				svc.$( "signGrantedColumns", "sig" );
				svc.$( "$translatePropertyName", "Label" );

				config = svc.getToolbarConfig(
					  objectName       = "my_extension_object"
					, gridFields       = [ "label" ]
					, hiddenGridFields = []
					, allowSavedViews  = true
				);

				expect( config.resolvedDefaultViewId ).toBe( "view-1" );

				svc.$( "resolveDefaultView", {} );

				config = svc.getToolbarConfig(
					  objectName       = "my_extension_object"
					, gridFields       = [ "label" ]
					, hiddenGridFields = []
					, allowSavedViews  = true
				);

				expect( config.resolvedDefaultViewId ).toBe( "" );
			} );
		} );

		describe( "saveListingViewDefault()", function(){
			it( "should refuse group and everyone defaults without share permission", function(){
				var svc = _getService();

				svc.$( "$getAdminLoggedInUserId", "user-1" );

				expect( svc.saveListingViewDefault(
					  viewId     = "view-1"
					, objectName = "my_extension_object"
					, scope      = "global"
					, canShare   = false
				).success ).toBeFalse();
			} );

			it( "should refuse an everyone default unless the view is shared globally", function(){
				var svc         = _getService();
				var mockViewDao = createStub();

				svc.$( "$getAdminLoggedInUserId", "user-1" );
				svc.$( "listSavedViews", [ { id="view-1", label="Mine" } ] );
				svc.$( "$getPresideObject" ).$args( "admin_datatable_saved_view" ).$results( mockViewDao );
				mockViewDao.$( "selectData", QueryNew( "id,sharing_scope,is_shared", "varchar,varchar,varchar", [ [ "view-1", "individual", "0" ] ] ) );

				expect( svc.saveListingViewDefault(
					  viewId     = "view-1"
					, objectName = "my_extension_object"
					, scope      = "global"
					, canShare   = true
				).success ).toBeFalse();
			} );
		} );
	}

	private any function _getService( struct dataManagerDefaults ) {
		var mockHelpers = createStub();
		var svc         = "";

		variables.mockDataManager    = createStub();
		variables.mockCustomization  = createStub();
		variables.mockEnum           = createStub();
		variables.mockSessionStorage = createStub();
		variables.mockCustomFields   = createStub();

		variables.mockCustomization.$( "runCustomization", "" );
		variables.mockSessionStorage.$( "getVar", "unit-test-listing-hmac-key" );
		variables.mockSessionStorage.$( "setVar" );

		svc = CreateMock( object=new preside.system.services.admin.DataListingPreferencesService(
			  dataManagerService       = variables.mockDataManager
			, customizationService     = variables.mockCustomization
			, enumService              = variables.mockEnum
			, sessionStorage           = variables.mockSessionStorage
			, rulesEngineFilterService = NullValue()
			, customFieldsService      = variables.mockCustomFields
			, dataManagerDefaults      = arguments.dataManagerDefaults ?: { columnPickerFields="auto" }
		) );

		svc.$property( propertyName="$helpers", mock=mockHelpers );
		mockHelpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );

		return svc;
	}

}
