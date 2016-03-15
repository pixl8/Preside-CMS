<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

<!--- tests --->
	<cffunction name="test01_formExists_shouldReturnTrue_whenPassedFormId_matchesFileNameOfAFormInTheConfiguredFormDirectories_minusTheFileExtension" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );

			super.assert( formsSvc.formExists( "test.form" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test02_formExists_shouldReturnFalse_whenPassedFormId_doesNotMatchAForm" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );

			super.assertFalse( formsSvc.formExists( "test.form.that.does.not.exist" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test03_formExists_shouldReturnTrue_whenFormExistsInOneOfManyFolders" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );

			super.assert( formsSvc.formExists( "test.form.unique.to.set3" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test04_formExists_shouldReturnTrue_whenFormExistsInManyOfManyFolders" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );

			super.assert( formsSvc.formExists( "test.form" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test05_formExists_shouldReturnFalse_whenFormDoesNotExistInAnyOfManyFolders" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );

			super.assertFalse( formsSvc.formExists( "test.form.that.does.not.exist" ) );
		</cfscript>
	</cffunction>

	<cffunction name="test06_getForm_shouldReturnStructureOfFormDefinitionAsDefinedInXml" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
			var result   = formsSvc.getForm( "test.form" );
			var expected = {
				tabs = [{
					title="{forms:tab1.title}",
					description="{forms:tab1.description}",
					id="",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[{
							name="somefield1", control="testcontrol", required="true", maxLength="50", label="{forms:some.field.label}", hint="{forms.some.field.hint}", rules=[]
						},{
							name="somefield2", control="spinner", step="2", minValue="0", maxValue="10", required="false", label="{forms:some.field2.label}", hint="{forms.some.field2.hint}", rules=[]
						}]
					}]

				},{
					title="{forms:tab2.title}",
					description="{forms:tab2.description}",
					id="",
					fieldsets=[{
						title="{test:test.fieldset.title}",
						description="",
						id="",
						fields=[{
							name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[]
						}]
					},{
						title="{test:test.fieldset2.title}",
						description="{test:test.fieldset2.description}",
						id="",
						fields=[{
							name="somefield4", control="spinner", step="5", minValue="0", maxValue="100", required="false", default="10", rules=[
								  { validator="required", serverCondition="${somefield3} gt 10", clientCondition="${somefield3}.val() > 10", params={} }
								, { validator="sameAs", params={field="somefield1"} }
							]
						}]
					}]
				}]
			};

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test08_readForm_shouldReturnInformativeError_whenFormIsMalformedXml" returntype="void">
		<cfscript>
			var errorThrown = false;

			try {
				_getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms3,/tests/resources/formsService/badForm" );
			} catch ( "FormsService.BadFormXml" e ) {
				super.assertEquals( "The form definition file, [bad.form.xml], does not contain valid XML", e.message );
				super.assertEquals( "XML document structures must start and end within the same entity.", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test09_readForm_shouldMergeFieldDefinitionsFromComponentFields_whenFieldsSpecifyComponentBindings_withFormFieldDefinitionsTakingPrecidence" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/forms2,/tests/resources/formsService/forms3,/tests/resources/formsService/forms4" );
			var result   = formsSvc.getForm( "event.cms.add" );
			var expected = {
				feature = "enabled-feature",
				tabs = [{
					title       = "",
					description = "",
					id="",
					fieldsets   = [{
						title       = "",
						description = "",
						id="",
						fields=[ {
							  name         = "known_as"
							, type         = "string"
							, dbtype       = "varchar"
							, maxLength    = "50"
							, required     = "false"
							, control      = "overridenControl"
							, generator    = "none"
							, relatedto    = "none"
							, relationship = "none"
							, sourceObject = "security_user"
							, binding      = "security_user.known_as"
							, rules        = []
							, label        = "preside-objects.security_user:field.known_as.title"
							, placeholder  = "preside-objects.security_user:field.known_as.placeholder"
							, help         = "preside-objects.security_user:field.known_as.help"
						} ]
					}]

				}]
			};

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test10_init_shouldThrowInformativeError_whenFormFieldBindingIsMalformed" returntype="void">
		<cfscript>
			var errorThrown = false;

			try {
				_getFormsService( "/tests/resources/formsService/malformedBinding" );
			} catch ( "FormsService.MalformedBinding" e ) {
				super.assertEquals( "The binding [malformed] was malformed. Bindings should take the form, [presideObjectName.fieldName]", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test11_init_shouldThrownInformativeError_whenObjectReferedToInBindingDoesNotExist" returntype="void">
		<cfscript>
			var errorThrown = false;

			try {
				_getFormsService( "/tests/resources/formsService/bindingWithMissingObject" );
			} catch ( "FormsService.BadBinding" e ) {
				super.assertEquals( "The preside object, [missingObject], referred to in the form field binding, [missingObject.id], could not be found. Valid objects are #SerializeJson( poService.listObjects() )#", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test12_init_shouldThrowInformativeError_whenFieldReferedToInBindingDoesNotExist" returntype="void">
		<cfscript>
			var errorThrown = false;

			try {
				_getFormsService( "/tests/resources/formsService/bindingWithMissingField" );
			} catch ( "FormsService.BadBinding" e ) {
				super.assertEquals( "The field, [missingField], referred to in the form field binding, [page.missingField], could not be found in Preside Object, [page]", e.message );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test13_getDefaultFormForPresideObject_shouldReturnAFormWithOneTabAndOneFieldsetContainingAllFieldsFormTheGivenPresideObject" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms4" );
			var result   = formsSvc.getDefaultFormForPresideObject( objectName="security_group" );
			var expected = {
				tabs = [{
					id="default",
					title="preside-objects.security_group:tab.default.title",
					description="preside-objects.security_group:tab.default.description",
					iconclass="preside-objects.security_group:tab.default.iconclass",
					autoGeneratedAttributes=["title","description","iconclass"],
					fieldsets=[{
						id="default",
						title="preside-objects.security_group:fieldset.default.title",
						description="preside-objects.security_group:fieldset.default.description",
						autoGeneratedAttributes=["title","description"],
						fields=[{
							name="label", control="textinput", type="string", dbtype="varchar", maxLength="250", uniqueindexes="role_name", relationship="none", relatedTo="none", generator="none", required="true", sourceObject="security_group", label="preside-objects.security_group:field.label.title", help="preside-objects.security_group:field.label.help", placeholder="preside-objects.security_group:field.label.placeholder"
						},{
							name="description", control="default", type="string", dbtype="varchar", maxLength="200", required="false", relationship="none", relatedTo="none", generator="none", sourceObject="security_group", label="preside-objects.security_group:field.description.title", help="preside-objects.security_group:field.description.help", placeholder="preside-objects.security_group:field.description.placeholder"
						},{
							name="roles", control="rolepicker", multiple="true", type="string", dbtype="varchar", maxLength="1000", relationship="none", relatedTo="none", generator="none", required="false", sourceObject="security_group", label="preside-objects.security_group:field.roles.title", help="preside-objects.security_group:field.roles.help", placeholder="preside-objects.security_group:field.roles.placeholder"
						}]
					}]
				}]
			};

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test14_listForms_shouldReturnEmptyArray_whenNoFormsRegistered" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/idonotexist" );
			var result   = formsSvc.listForms();

			super.assertEquals( [], result );
		</cfscript>
	</cffunction>

	<cffunction name="test15_listForms_shouldReturnArrayOfRegisteredFormNames" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms4" );
			var expected = [ "event.cms.add", "event.cms.edit" ];
			var result   = formsSvc.listForms();

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test17_listFields_shouldReturnArrayOfFieldNamesInTheForm" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
			var result   = formsSvc.listFields( "test.form" );
			var expected = [ "somefield1", "somefield2", "somefield3", "somefield4" ];

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test18_getForm_shouldReturnDefaultFormForPresideObject_whenFormDoesNotExistAndFirstPartOfFormNameIsAValidComponent" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
			var result   = formsSvc.getForm( "preside-objects.security_group.add.form" );
			var expected = {
				tabs = [{
					id="default",
					title="preside-objects.security_group:tab.default.title",
					description="preside-objects.security_group:tab.default.description",
					iconClass="preside-objects.security_group:tab.default.iconClass",
					autoGeneratedAttributes=["title","description","iconClass"],
					fieldsets=[{
						id="default",
						title="preside-objects.security_group:fieldset.default.title",
						description="preside-objects.security_group:fieldset.default.description",
						autoGeneratedAttributes=["title","description"],
						fields=[{
							name="label", control="textinput", type="string", dbtype="varchar", maxLength="250", uniqueindexes="role_name", relationship="none", relatedTo="none", generator="none", required="true", sourceObject="security_group", label="preside-objects.security_group:field.label.title", help="preside-objects.security_group:field.label.help", placeholder="preside-objects.security_group:field.label.placeholder"
						},{
							name="description", control="default", type="string", dbtype="varchar", maxLength="200", required="false", relationship="none", relatedTo="none", generator="none", sourceObject="security_group", label="preside-objects.security_group:field.description.title", help="preside-objects.security_group:field.description.help", placeholder="preside-objects.security_group:field.description.placeholder"
						},{
							name="roles", control="rolepicker", multiple="true", type="string", dbtype="varchar", maxLength="1000", relationship="none", relatedTo="none", generator="none", required="false", sourceObject="security_group", label="preside-objects.security_group:field.roles.title", help="preside-objects.security_group:field.roles.help", placeholder="preside-objects.security_group:field.roles.placeholder"
						}]
					}]
				}]
			};

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test19_getForm_shouldThrowSuitableError_whenFormDoesNotExist" returntype="void">
		<cfscript>
			var formsSvc    = _getFormsService( "/tests/resources/formsService/forms1" );
			var errorThrown = false;

			try {
				formsSvc.getForm( "someform.that.does.not.exist" );
			} catch( "FormsService.MissingForm" e ) {
				super.assertEquals( "The form, [someform.that.does.not.exist], could not be found", e.message );
				errorThrown = true;
			} catch( any e ) {
				super.fail( "The wrong kind of error was thrown. Expected [FormsService.MissingForm], but received, [#e.type#]")
			}

			super.assert( errorThrown, "A suitable error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test20_getFormField_shouldReturnSpecifiedFieldFromForm" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1" );
			var result   = formsSvc.getFormField( formName="test.form", fieldName="somefield3" );
			var expected = { name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[] };

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test21_getFormField_shouldThrowSuitableError_whenFieldDoesNotExist" returntype="void">
		<cfscript>
			var formsSvc    = _getFormsService( "/tests/resources/formsService/forms1" );
			var errorThrown = false;

			try {
				formsSvc.getFormField( formName="test.form", fieldName="Does not exist" );
			} catch( "FormsService.MissingField" e ) {
				super.assertEquals( "The form field, [Does not exist], could not be found in the form, [test.form]", e.message );
				errorThrown = true;
			} catch( any e ) {
				super.fail( "The wrong kind of error was thrown. Expected [FormsService.MissingField], but received, [#e.type#]")
			}

			super.assert( errorThrown, "A suitable error was not thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test22_mergeForms_shouldReturnASingleFormComposedOfTwoForms" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/merging" );
			var result   = formsSvc.mergeForms( "form1", "form2" );
			var expected = {
				tabs = [{
					title="A new title",
					description="",
					id = "sometab",
					fieldsets=[{
						title="Another new title",
						description="A description",
						id="somefieldset",
						fields=[
							{ name="anotherfield", rules=[], sortorder=5 },
							{ name="somename", control="overridenControl", required="false", rules=[], sortorder=10 }
						]
					},{
						title="",
						description="",
						id="",
						fields=[
							{ name="meh", required=false, rules=[] }
						]
					},{
						title="",
						description="",
						id="",
						fields=[
							{ name="meh2", blah="blah", rules=[] }
						]
					}]

				},{
					title="",
					description="",
					id = "",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[
							{ name="mehsomemore", required="false", rules=[] }
						]
					}]
				},{
					title="",
					description="",
					id = "",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[
							{ name="intab3", required="false", rules=[] }
						]
					}]
				}]
			};

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test23_formsFromDifferentSourceFoldersButWithSameName_shouldBeAutomaticallyMerged" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/automerging/folder1,/tests/resources/formsService/automerging/folder2" );
			var result   = formsSvc.getForm( "someForm" );
			var expected = {
				tabs = [{
					title="A new title",
					description="",
					id = "sometab",
					fieldsets=[{
						title="Another new title",
						description="A description",
						id="somefieldset",
						fields=[
							{ name="anotherfield", rules=[], sortorder=5 },
							{ name="somename", control="overridenControl", required="false", rules=[], sortorder=10 }
						]
					},{
						title="",
						description="",
						id="",
						fields=[
							{ name="meh", required=false, rules=[] }
						]
					},{
						title="",
						description="",
						id="",
						fields=[
							{ name="meh2", blah="blah", rules=[] }
						]
					}]

				},{
					title="",
					description="",
					id = "",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[
							{ name="mehsomemore", required="false", rules=[] }
						]
					}]
				},{
					title="",
					description="",
					id = "",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[
							{ name="intab3", required="false", rules=[] }
						]
					}]
				}]
			};

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test24_formsInSiteTemplates_shouldNotBeMerged_whenTheSiteTemplateIsNotActiveForTheRequest" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/site-templates/mysite/forms" );
			var result   = formsSvc.getForm( "test.form" );
			var expected = {
				tabs = [{
					title="{forms:tab1.title}",
					description="{forms:tab1.description}",
					id="",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[{
							name="somefield1", control="testcontrol", required="true", maxLength="50", label="{forms:some.field.label}", hint="{forms.some.field.hint}", rules=[]
						},{
							name="somefield2", control="spinner", step="2", minValue="0", maxValue="10", required="false", label="{forms:some.field2.label}", hint="{forms.some.field2.hint}", rules=[]
						}]
					}]

				},{
					title="{forms:tab2.title}",
					description="{forms:tab2.description}",
					id="",
					fieldsets=[{
						title="{test:test.fieldset.title}",
						description="",
						id="",
						fields=[{
							name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[]
						}]
					},{
						title="{test:test.fieldset2.title}",
						description="{test:test.fieldset2.description}",
						id="",
						fields=[{
							name="somefield4", control="spinner", step="5", minValue="0", maxValue="100", required="false", default="10", rules=[
								  { validator="required", serverCondition="${somefield3} gt 10", clientCondition="${somefield3}.val() > 10", params={} }
								, { validator="sameAs", params={field="somefield1"} }
							]
						}]
					}]
				}]
			};

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test25_formsInSiteTemplates_shouldNotBeMerged_whenTheSiteTemplateIsNotActiveForTheRequest" returntype="void">
		<cfscript>
			var formsSvc = _getFormsService( "/tests/resources/formsService/forms1,/tests/resources/formsService/site-templates/mysite/forms", "mysite" );
			var result   = formsSvc.getForm( "test.form" );
			var expected = {
				tabs = [{
					title="{forms:tab1.title}",
					description="{forms:tab1.description}",
					id="",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[{
							name="somefield1", control="testcontrol", required="true", maxLength="50", label="{forms:some.field.label}", hint="{forms.some.field.hint}", rules=[]
						},{
							name="somefield2", control="spinner", step="2", minValue="0", maxValue="10", required="false", label="{forms:some.field2.label}", hint="{forms.some.field2.hint}", rules=[]
						}]
					}]

				},{
					title="{forms:tab2.title}",
					description="{forms:tab2.description}",
					id="",
					fieldsets=[{
						title="{test:test.fieldset.title}",
						description="",
						id="",
						fields=[{
							name="somefield3", control="spinner", step="3", minValue="0", maxValue="10", required="false", label="{forms:some.field3.label}", hint="{forms.some.field3.hint}", rules=[]
						}]
					},{
						title="{test:test.fieldset2.title}",
						description="{test:test.fieldset2.description}",
						id="",
						fields=[{
							name="somefield4", control="spinner", step="5", minValue="0", maxValue="100", required="false", default="10", rules=[
								  { validator="required", serverCondition="${somefield3} gt 10", clientCondition="${somefield3}.val() > 10", params={} }
								, { validator="sameAs", params={field="somefield1"} }
							]
						}]
					}]
				},{
					title="",
					description="",
					id="",
					fieldsets=[{
						title="",
						description="",
						id="",
						fields=[{ name="test", rules=[] }]
					}]

				}]
			};

			result = formsSvc.getForm( "test.form" );

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_getFormsService" access="private" returntype="any" output="false">
		<cfargument name="formDirectories"    type="string" required="true" />
		<cfargument name="activeSiteTemplate" type="string" required="false" default="" />

		<cfscript>
			mockI18nPlugin              = getMockBox().createMock( "preside.system.coldboxModifications.plugins.i18n" );
			mockColdBox                 = getMockBox().createMock( "preside.system.coldboxModifications.Controller" );
			mockSiteService             = getMockBox().createMock( "preside.system.services.siteTree.SiteService" );
			mockValidationRuleGenerator = getMockBox().createEmptyMock( "preside.system.services.validation.PresideFieldRuleGenerator" );
			mockFeatureService          = getMockBox().createEmptyMock( "preside.system.services.features.FeatureService" );
			poService                   = _getPresideObjectService();

			mockSiteService.$( "getActiveSiteTemplate", arguments.activeSiteTemplate );
			mockValidationRuleGenerator.$( "generateRulesFromPresideForm", [] );

			mockFeatureService.$( "isFeatureEnabled" ).$args( "enabled-feature" ).$results( true );
			mockFeatureService.$( "isFeatureEnabled" ).$args( "disabled-feature" ).$results( false );
			mockFeatureService.$( "isFeatureEnabled", true );

			return new preside.system.services.forms.FormsService(
				  presideObjectService = poService
				, siteService          = mockSiteService
				, logger               = _getTestLogger()
				, formDirectories      = ListToArray( arguments.formDirectories )
				, validationEngine     = new preside.system.services.validation.ValidationEngine()
				, i18n                 = mockI18nPlugin
				, coldbox              = mockColdBox
				, presideFieldRuleGenerator = mockValidationRuleGenerator
				, defaultContextName   = "index"
				, configuredControls   = {}
				, featureService       = mockFeatureService
			);
		</cfscript>
	</cffunction>

</cfcomponent>