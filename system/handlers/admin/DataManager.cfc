<cfcomponent output="false" extends="preside.system.base.AdminHandler">

	<cfproperty name="presideObjectService"             inject="presideObjectService"             />
	<cfproperty name="multilingualPresideObjectService" inject="multilingualPresideObjectService" />
	<cfproperty name="dataManagerService"               inject="dataManagerService"               />
	<cfproperty name="formsService"                     inject="formsService"                     />
	<cfproperty name="validationEngine"                 inject="validationEngine"                 />
	<cfproperty name="siteService"                      inject="siteService"                      />
	<cfproperty name="messageBox"                       inject="coldbox:plugin:messageBox"        />

	<cffunction name="preHandler" access="public" returntype="void" output="false">
		<cfargument name="event"          type="any"    required="true" />
		<cfargument name="action"         type="string" required="true" />
		<cfargument name="eventArguments" type="struct" required="true" />

		<cfscript>
			super.preHandler( argumentCollection = arguments );

			if ( !isFeatureEnabled( "datamanager" ) ) {
				event.notFound();
			}

			event.addAdminBreadCrumb(
				  title = translateResource( "cms:datamanager" )
				, link  = event.buildAdminLink( linkTo="datamanager" )
			);
		</cfscript>
	</cffunction>

	<cffunction name="index" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			_checkNavigatePermission( argumentCollection=arguments );

			prc.objectGroups = dataManagerService.getGroupedObjects();
		</cfscript>
	</cffunction>

	<cffunction name="object" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName   = event.getValue( name="id", default="" );
			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_checkPermission( argumentCollection=arguments, key="navigate", object=objectName );

			_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );

			_addObjectNameBreadCrumb( event, objectName );

			prc.canAdd    = datamanagerService.isOperationAllowed( objectName, "add" )    && hasCmsPermission( permissionKey="datamanager.add", context="datamanager", contextkeys=[ objectName ] );
			prc.canDelete = datamanagerService.isOperationAllowed( objectName, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] );
			prc.canSort   = datamanagerService.isSortable( objectName ) && hasCmsPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ objectName ] );

			prc.gridFields          = _getObjectFieldsForGrid( objectName );
			prc.batchEditableFields = dataManagerService.listBatchEditableFields( objectName );
			prc.isMultilingual      = multilingualPresideObjectService.isMultilingual( objectName );
		</cfscript>
	</cffunction>

	<cffunction name="getObjectRecordsForAjaxDataTables" access="public" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />

		<cfscript>
			var objectName = rc.id ?: "";

			_checkPermission( argumentCollection=arguments, key="read", object=objectName );

			runEvent(
				  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object              = objectName
					, useMultiActions     = hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] )
					, gridFields          = ( rc.gridFields          ?: 'label,datecreated,datemodified' )
					, isMultilingual      = ( rc.isMultilingual      ?: 'false' )
				}
			);
		</cfscript>
	</cffunction>

	<cffunction name="getChildObjectRecordsForAjaxDataTables" access="public" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />

		<cfscript>
			var objectName      = rc.object          ?: "";
			var parentId        = rc.parentId        ?: "";
			var relationshipKey = rc.relationshipKey ?: "";

			runEvent(
				  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object          = objectName
					, useMultiActions = hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] )
					, gridFields      = ( rc.gridFields ?: 'label,datecreated,datemodified' )
					, actionsView     = "/admin/datamanager/_oneToManyListingActions"
					, filter          = { "#relationshipKey#" : parentId }
				}
			);
		</cfscript>
	</cffunction>

	<cffunction name="_oneToManyListingActions" access="private" returntype="string" output="false">
		<cfargument name="event" type="any"     required="true" />
		<cfargument name="rc"    type="struct"  required="true" />
		<cfargument name="prc"   type="struct"  required="true" />
		<cfargument name="args"  type="struct"  required="false" default="#StructNew()#" />

		<cfscript>
			var objectName = args.objectName ?: "";

			args.canEdit   = datamanagerService.isOperationAllowed( objectName, "edit"   );
			args.canDelete = datamanagerService.isOperationAllowed( objectName, "delete" );

			return renderView( view="/admin/datamanager/_oneToManyListingActions", args=args );
		</cfscript>
	</cffunction>

	<cffunction name="getRecordHistoryForAjaxDataTables" access="public" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />

		<cfscript>
			var objectName = rc.object ?: "";
			var recordId   = rc.id     ?: "";

			_checkPermission( argumentCollection=arguments, key="viewversions", object=objectName );

			runEvent(
				  event          = "admin.DataManager._getRecordHistoryForAjaxDataTables"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object     = objectName
					, recordId   = recordId
					, gridFields = ( rc.gridFields ?: 'datemodified,label' )
				}
			);
		</cfscript>
	</cffunction>

	<cffunction name="getTranslationRecordHistoryForAjaxDataTables" access="public" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />

		<cfscript>
			var objectName = rc.object   ?: "";
			var recordId   = rc.id       ?: "";
			var languageId = rc.language ?: "";

			_checkPermission( argumentCollection=arguments, key="translate", object=objectName );
			_checkPermission( argumentCollection=arguments, key="viewversions", object=objectName );

			runEvent(
				  event          = "admin.DataManager._getTranslationRecordHistoryForAjaxDataTables"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object     = objectName
					, recordId   = recordId
					, languageId = languageId
					, gridFields = ( rc.gridFields ?: 'datemodified,label' )
				}
			);
		</cfscript>
	</cffunction>



	<cffunction name="getObjectRecordsForAjaxSelectControl" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkPermission( argumentCollection=arguments, key="read", object=objectName );

			var records = dataManagerService.getRecordsForAjaxSelect(
				  objectName   = rc.object  ?: ""
				, maxRows      = rc.maxRows ?: 1000
				, searchQuery  = rc.q       ?: ""
				, savedFilters = ListToArray( rc.savedFilters ?: "" )
				, ids          = ListToArray( rc.values ?: "" )
			);

			event.renderData( type="json", data=records );
		</cfscript>
	</cffunction>

	<cffunction name="managePerms" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = event.getValue( name="object", defaultValue="" );

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="manageContextPerms", object=objectName );

			_addObjectNameBreadCrumb( event, objectName );

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.managePerms.breadcrumb.title" )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="savePermsAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = event.getValue( name="object", defaultValue="" );

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="manageContextPerms", object=objectName );

			if ( runEvent( event="admin.Permissions.saveContextPermsAction", private=true ) ) {
				messageBox.info( translateResource( uri="cms:datamanager.permsSaved.confirmation", data=[ objectName ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#objectName#" ) );
			}

			messageBox.error( translateResource( uri="cms:datamanager.permsSaved.error", data=[ objectName ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.managePerms", queryString="object=#objectName#" ) );

		</cfscript>
	</cffunction>

	<cffunction name="viewRecord" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = rc.object ?: "";
			var recordId   = rc.id     ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="read", object=objectName );

			// temporary redirect to edit record (we haven't implemented view record yet!)
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="id=#recordId#&object=#objectName#" ) );
		</cfscript>
	</cffunction>

	<cffunction name="recordHistory" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object     = rc.object ?: "";
			var objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var recordId   = rc.id     ?: "";

			_checkObjectExists( argumentCollection=arguments, object=object );
			_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="viewversions", object=object );

			if ( !presideObjectService.objectIsVersioned( object ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNot.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
			if ( not prc.record.recordCount ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			// breadcrumb setup
			_addObjectNameBreadCrumb( event, object );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.recordhistory.breadcrumb.title" )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="translationRecordHistory" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object     = rc.object   ?: "";
			var recordId   = rc.id       ?: "";
			var languageId = rc.language ?: "";
			var objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );

			prc.language = multilingualPresideObjectService.getLanguage( languageId );

			if ( prc.language.isempty() ) {
				messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
			}

			_checkObjectExists( argumentCollection=arguments, object=object );
			_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="translate"   , object=object );
			_checkPermission( argumentCollection=arguments, key="viewversions", object=object );

			if ( !presideObjectService.objectIsVersioned( object ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
			if ( not prc.record.recordCount ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}
			prc.recordLabel = prc.record[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

			// breadcrumb setup
			_addObjectNameBreadCrumb( event, object );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.translaterecord.breadcrumb.title", data=[ prc.language.name ] )
				, link  = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#recordId#&language=#languageId#" )
			);
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.translationRecordhistory.breadcrumb.title" )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="batchEditField" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object      = rc.object;
			var field       = rc.field ?: "";
			var formControl = {};
			var ids         = rc.id ?: "";
			var recordCount = ListLen( Trim( ids ) );
			var objectName  = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
			var fieldName   = translateResource( uri="preside-objects.#object#:field.#field#.title", defaultValue=field );

			_checkObjectExists( argumentCollection=arguments, object=object );
			_checkPermission( argumentCollection=arguments, key="edit", object=object );
			if ( !recordCount ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			prc.fieldFormControl = formsService.renderFormControlForObjectField(
			      objectName = object
			    , fieldName  = field
			);

			if ( presideObjectService.isManyToManyProperty( object, field ) ) {
				prc.multiEditBehaviourControl = renderFormControl(
					  type   = "select"
					, name   = "multiValueBehaviour"
					, label  = translateResource( uri="cms:datamanager.multiValueBehaviour.title" )
					, values = [ "append", "overwrite", "delete" ]
					, labels = [ translateResource( uri="cms:datamanager.multiDataAppend.title" ), translateResource( uri="cms:datamanager.multiDataOverwrite.title" ), translateResource( uri="cms:datamanager.multiDataDeleteSelected.title" ) ]
				);

				prc.batchEditWarning = translateResource(
					  uri  = "cms:datamanager.batch.edit.warning.multi.value"
					, data = [ "<strong>#objectName#</strong>", "<strong>#fieldName#</strong>", "<strong>#NumberFormat( recordCount )#</strong>" ]
				);
			} else {
				prc.batchEditWarning = translateResource(
					  uri  = "cms:datamanager.batch.edit.warning"
					, data = [ "<strong>#objectName#</strong>", "<strong>#fieldName#</strong>", "<strong>#NumberFormat( recordCount )#</strong>" ]
				);
			}

			prc.pageTitle    = translateResource( uri="cms:datamanager.batchEdit.page.title"   , data=[ objectName, NumberFormat( recordCount ) ] );
			prc.pageSubtitle = translateResource( uri="cms:datamanager.batchEdit.page.subtitle", data=[ fieldName ] );
			prc.pageIcon     = "pencil";

			_addObjectNameBreadCrumb( event, object );

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.batchedit.breadcrumb.title", data=[ objectName, fieldName ] )
				, link  = ""
			);

			event.setView( view="/admin/datamanager/batchEditField" );
		</cfscript>
	</cffunction>

	<cffunction name="batchEditAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var updateField = rc.updateField ?: "";
			var objectName  = rc.objectName  ?: "";
			var sourceIds   = ListToArray( Trim( rc.sourceIds ?: "" ) );

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_checkPermission( argumentCollection=arguments, key="edit", object=objectName );
			if ( !sourceIds.len() ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			var success = datamanagerService.batchEditField(
				  objectName         = objectName
				, fieldName          = updateField
				, sourceIds          = sourceIds
				, value              = rc[ updateField ]      ?: ""
				, multiEditBehaviour = rc.multiValueBehaviour ?: "append"
			);

			if( success ) {
				messageBox.info( translateResource( uri="cms:datamanager.batchedit.confirmation", data=[ objectName ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#objectName#" ) );
			} else {
				messageBox.error( translateResource( uri="cms:datamanager.batchedit.error", data=[ objectName ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#objectName#" ) );
			}
		</cfscript>
	</cffunction>

	<cffunction name="deleteRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_checkPermission( argumentCollection=arguments, key="delete", object=objectName );

			runEvent(
				  event          = "admin.DataManager._deleteRecordAction"
				, prePostExempt  = true
				, private        = true
			);
		</cfscript>
	</cffunction>

	<cffunction name="deleteOneToManyRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var objectName      = rc.object ?: "";
			var relationshipKey = rc.relationshipKey ?: "";
			var parentId        = rc.parentId ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			if ( !datamanagerService.isOperationAllowed( objectName, "delete"   ) ) {
				event.adminAccessDenied();
			}
			rc.forceDelete = true;

			runEvent(
				  event          = "admin.DataManager._deleteRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					postActionUrl  = event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", queryString="object=#objectName#&relationshipKey=#relationshipKey#&parentId=#parentId#" )
				}
			);
		</cfscript>
		<cfscript>

		</cfscript>
	</cffunction>

	<cffunction name="cascadeDeletePrompt" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_checkPermission( argumentCollection=arguments, key="delete", object=objectName );

			_addObjectNameBreadCrumb( event, objectName );

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.cascadeDelete.breadcrumb.title" )
				, link  = ""
			);

			prc.blockers = event.getValue( name="blockers", defaultValue={}, private=false );
			prc.id       = event.getValue( name="id", defaultValue="" );
		</cfscript>
	</cffunction>

	<cffunction name="addRecord" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = event.getValue( name="object", defaultValue="" );

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="add", object=objectName );

			_addObjectNameBreadCrumb( event, objectName );

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.addrecord.breadcrumb.title" )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="addRecordAction" access="public" returntype="any" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var objectName = rc.object ?: "";
			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_checkPermission( argumentCollection=arguments, key="add", object=objectName );

			runEvent(
				  event          = "admin.DataManager._addRecordAction"
				, prePostExempt  = true
				, private        = true
			);
		</cfscript>
	</cffunction>

	<cffunction name="addOneToManyRecordAction" access="public" returntype="any" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			if ( !datamanagerService.isOperationAllowed( objectName, "add"   ) ) {
				event.adminAccessDenied();
			}

			runEvent(
				  event          = "admin.DataManager._addOneToManyRecordAction"
				, prePostExempt  = true
				, private        = true
			);
		</cfscript>
	</cffunction>

	<cffunction name="quickAddForm" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object = rc.object ?: "";
			var args   = {};

			_checkObjectExists( argumentCollection=arguments, object=object );
			_checkPermission( argumentCollection=arguments, key="add", object=object );

			args.allowAddAnotherSwitch = IsTrue( rc.multiple ?: "" );

			event.setView( view="/admin/datamanager/quickAddForm", layout="adminModalDialog", args=args );
		</cfscript>
	</cffunction>

	<cffunction name="quickAddRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=object );
			_checkPermission( argumentCollection=arguments, key="add", object=object );

			runEvent(
				  event          = "admin.DataManager._quickAddRecordAction"
				, prePostExempt  = true
				, private        = true
			);
		</cfscript>
	</cffunction>

	<cffunction name="quickEditForm" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object = rc.object ?: "";
			var id     = rc.id     ?: "";

			_checkObjectExists( argumentCollection=arguments, object=object );
			_checkPermission( argumentCollection=arguments, key="edit", object=object );

			prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
			if ( prc.record.recordCount ) {
				prc.record = queryRowToStruct( prc.record );
			} else {
				prc.record = {};
			}

			event.setView( view="/admin/datamanager/quickEditForm", layout="adminModalDialog" );
		</cfscript>
	</cffunction>

	<cffunction name="quickEditRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_checkPermission( argumentCollection=arguments, key="edit", object=objectName );

			runEvent(
				  event          = "admin.DataManager._quickEditRecordAction"
				, prePostExempt  = true
				, private        = true
			);
		</cfscript>
	</cffunction>

	<cffunction name="editRecord" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object     = rc.object  ?: "";
			var id         = rc.id      ?: "";
			var version    = rc.version ?: "";
			var objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var record     = "";

			_checkObjectExists( argumentCollection=arguments, object=object );
			_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="edit", object=object );

			prc.useVersioning = datamanagerService.isOperationAllowed( object, "viewversions" ) && presideObjectService.objectIsVersioned( object );
			if ( prc.useVersioning && Val( version ) ) {
				prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false, fromVersionTable=true, specificVersion=version );
			} else {
				prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
			}

			if ( not prc.record.recordCount ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			prc.record = queryRowToStruct( prc.record );
			prc.recordLabel = prc.record[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

			prc.isMultilingual = multilingualPresideObjectService.isMultilingual( object );
			prc.canTranslate   = prc.isMultilingual && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] )
			prc.canDelete      = datamanagerService.isOperationAllowed( object, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] );

			if ( prc.canTranslate ) {
				prc.translations = multilingualPresideObjectService.getTranslationStatus( object, id );
			}

			// breadcrumb setup
			_addObjectNameBreadCrumb( event, object );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.editrecord.breadcrumb.title" )
				, link  = ""
			);
		</cfscript>
	</cffunction>

	<cffunction name="editRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			_checkPermission( argumentCollection=arguments, key="edit", object=objectName );

			runEvent(
				  event          = "admin.DataManager._editRecordAction"
				, prePostExempt  = true
				, private        = true
			);
		</cfscript>
	</cffunction>

	<cffunction name="translateRecord" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object                = rc.object   ?: "";
			var id                    = rc.id       ?: "";
			var version               = rc.version  ?: "";
			var objectName            = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( object );
			var record                = "";

			prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );

			if ( prc.language.isempty() ) {
				messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
			}

			_checkObjectExists( argumentCollection=arguments, object=object );
			_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="translate", object=object );


			prc.useVersioning = presideObjectService.objectIsVersioned( object );
			prc.sourceRecord = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );

			if ( prc.useVersioning && Val( version ) ) {
				prc.record       = multiLingualPresideObjectService.selectTranslation( objectName=object, id=id, languageId=prc.language.id, useCache=false, version=version );
			} else {
				prc.record       = multiLingualPresideObjectService.selectTranslation( objectName=object, id=id, languageId=prc.language.id, useCache=false );
			}

			if ( not prc.sourceRecord.recordCount ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			prc.record = queryRowToStruct( prc.record );
			prc.recordLabel = prc.sourceRecord[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

			prc.canDelete = datamanagerService.isOperationAllowed( object, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] );
			prc.translations = multilingualPresideObjectService.getTranslationStatus( object, id );
			prc.formName = "preside-objects.#translationObjectName#.admin.edit";

			_addObjectNameBreadCrumb( event, object );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.translaterecord.breadcrumb.title", data=[ prc.language.name ] )
				, link  = ""
			);
			prc.pageIcon  = "pencil";
			prc.pageTitle = translateResource( uri="cms:datamanager.translaterecord.title", data=[ objectName, prc.recordLabel, prc.language.name ] );
		</cfscript>
	</cffunction>

	<cffunction name="translateRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"     required="true" />
		<cfargument name="rc"    type="struct"  required="true" />
		<cfargument name="prc"   type="struct"  required="true" />

		<cfscript>
			var id                    = rc.id       ?: "";
			var object                = rc.object   ?: "";
			var languageId            = rc.language ?: "";
			var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( object );

			_checkObjectExists( argumentCollection=arguments, object=object );
			_checkPermission( argumentCollection=arguments, key="translate", object=object );

			prc.language = multilingualPresideObjectService.getLanguage( rc.language ?: "" );
			if ( prc.language.isempty() ) {
				messageBox.error( translateResource( uri="cms:multilingual.language.not.active.error" ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
			}

			if ( not presideObjectService.dataExists( objectName=object, filter={ id=id } ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			var formName         = "preside-objects.#translationObjectName#.admin.edit";
			var version          = rc.version ?: "";
			var formData         = event.getCollectionForForm( formName );
			var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var existingTranslation = multilingualPresideObjectService.selectTranslation(
				  objectName   = object
				, id           = id
				, languageId   = languageId
				, selectFields = [ "id" ]
			);

			var obj              = "";
			var persist          = "";

			formData._translation_language = languageId;
			if ( existingTranslation.recordCount ) {
				formData.id = existingTranslation.id;
			}
			var validationResult = validateForm( formName=formName, formData=formData );

			if ( not validationResult.validated() ) {
				messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;
				persist.delete( "id" );

				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.translateRecord", querystring="id=#id#&object=#object#&version=#version#&language=#languageId#" ), persistStruct=persist );
			}

			formData._translation_active = IsTrue( rc._translation_active ?: "" );
			multilingualPresideObjectService.saveTranslation(
				  objectName = object
				, id         = id
				, data       = formData
				, languageId = languageId
			);

			messageBox.info( translateResource( uri="cms:datamanager.recordTranslated.confirmation", data=[ objectName ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" ) );
		</cfscript>
	</cffunction>

	<cffunction name="multiRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var object     = rc.object      ?: "";
			var action     = rc.multiAction ?: "";
			var ids        = rc.id          ?: "";
			var listingUrl = event.buildAdminLink( linkTo=rc.postAction ?: "datamanager.object", queryString="id=#object#" );

			_checkObjectExists( argumentCollection=arguments, object=object );

			if ( not Len( Trim( ids ) ) ) {
				messageBox.error( translateResource( "cms:datamanager.norecordsselected.error" ) );
				setNextEvent( url=listingUrl );
			}

			switch( action ){
				case "batchUpdate":
					setNextEvent(
						  url           = event.buildAdminLink( linkTo="datamanager.batchEditField", queryString="object=#object#&field=#( rc.field ?: '' )#" )
						, persistStruct = { id = ids }
					);
				break;
				case "delete":
					return deleteRecordAction( argumentCollection = arguments );
				break;
			}

			messageBox.error( translateResource( "cms:datamanager.invalid.multirecord.action.error" ) );
			setNextEvent( url=listingUrl );
		</cfscript>
	</cffunction>

	<cffunction name="multiOneToManyRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var object          = rc.object          ?: "";
			var parentId        = rc.parentId        ?: "";
			var relationshipKey = rc.relationshipKey ?: "";
			var action          = rc.multiAction     ?: "";
			var ids             = rc.id              ?: "";
			var listingUrl      = event.buildAdminLink( linkTo=rc.postAction ?: "datamanager.manageOneToManyRecords", queryString="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#" );

			_checkObjectExists( argumentCollection=arguments, object=object );

			if ( not Len( Trim( ids ) ) ) {
				messageBox.error( translateResource( "cms:datamanager.norecordsselected.error" ) );
				setNextEvent( url=listingUrl );
			}

			switch( action ){
				case "delete":
					return deleteOneToManyRecordAction( argumentCollection = arguments );
				break;
			}

			messageBox.error( translateResource( "cms:datamanager.invalid.multirecord.action.error" ) );
			setNextEvent( url=listingUrl );
		</cfscript>
	</cffunction>


	<cffunction name="manageOneToManyRecords" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"     required="true" />
		<cfargument name="rc"    type="struct"  required="true" />
		<cfargument name="prc"   type="struct"  required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );

			var parentDetails = _getParentDetailsForOneToManyActions( event, rc, prc );
			var objectTitle   = translateResource( "preside-objects.#objectName#:title" );

			prc.gridFields    = _getObjectFieldsForGrid( objectName );
			prc.canAdd        = datamanagerService.isOperationAllowed( objectName, "add" );
			prc.delete        = datamanagerService.isOperationAllowed( objectName, "delete" );
			prc.pageTitle     = translateResource( uri="cms:datamanager.oneToManyListing.page.title"   , data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
			prc.pageSubTitle  = translateResource( uri="cms:datamanager.oneToManyListing.page.subtitle", data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
			prc.pageIcon      = "puzzle-piece";

			event.setLayout( "adminModalDialog" );
		</cfscript>
	</cffunction>

	<cffunction name="addOneToManyRecord" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = event.getValue( name="object", defaultValue="" );

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			if ( !datamanagerService.isOperationAllowed( objectName, "add"   ) ) {
				event.adminAccessDenied();
			}

			var parentDetails = _getParentDetailsForOneToManyActions( event, rc, prc );
			var objectTitle   = translateResource( "preside-objects.#objectName#:title.singular" );

			prc.pageTitle     = translateResource( uri="cms:datamanager.oneToMany.addRecord.page.title"   , data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
			prc.pageSubTitle  = translateResource( uri="cms:datamanager.oneToMany.addRecord.page.subtitle", data=[ objectTitle, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
			prc.pageIcon      = "plus";

			event.setLayout( "adminModalDialog" );
		</cfscript>
	</cffunction>

	<cffunction name="editOneToManyRecord" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var object          = rc.object          ?: "";
			var parentId        = rc.parentId        ?: "";
			var relationshipKey = rc.relationshipKey ?: "";
			var id              = rc.id              ?: "";
			var version         = rc.version         ?: "";
			var objectName      = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );

			_checkObjectExists( argumentCollection=arguments, object=object );
			if ( !datamanagerService.isOperationAllowed( object, "edit"   ) ) {
				event.adminAccessDenied();
			}

			prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
			if ( not prc.record.recordCount ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", querystring="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#" ) );
			}
			prc.record = queryRowToStruct( prc.record );
			prc.recordLabel = prc.record[ presideObjectService.getObjectAttribute( objectName=object, attributeName="labelfield", defaultValue="label" ) ] ?: "";

			var parentDetails = _getParentDetailsForOneToManyActions( event, rc, prc );

			prc.pageTitle     = translateResource( uri="cms:datamanager.oneToMany.editRecord.page.title"   , data=[ objectName, prc.recordLabel, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
			prc.pageSubTitle  = translateResource( uri="cms:datamanager.oneToMany.editRecord.page.subtitle", data=[ objectName, prc.recordLabel, parentDetails.parentObjectTitle, parentDetails.parentRecordLabel ] );
			prc.pageIcon      = "pencil";

			event.setLayout( "adminModalDialog" );
		</cfscript>
	</cffunction>

	<cffunction name="editOneToManyRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var id              = rc.id              ?: "";
			var object          = rc.object          ?: "";
			var parentId        = rc.parentId        ?: "";
			var relationshipKey = rc.relationshipKey ?: "";

			rc[ relationshipKey ] = parentId;

			_checkObjectExists( argumentCollection=arguments, object=object );
			if ( !datamanagerService.isOperationAllowed( object, "edit"   ) ) {
				event.adminAccessDenied();
			}

			runEvent(
				  event          = "admin.DataManager._editRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  errorUrl   = event.buildAdminLink( linkTo="datamanager.editOneToManyRecord"   , queryString="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#&id=#id#" )
					, successUrl = event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", queryString="object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#" )
				}
			);
		</cfscript>
	</cffunction>

	<cffunction name="sortRecords" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"     required="true" />
		<cfargument name="rc"    type="struct"  required="true" />
		<cfargument name="prc"   type="struct"  required="true" />

		<cfscript>
			var object           = rc.object  ?: "";
			var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var objectNamePlural = translateResource( uri="preside-objects.#object#:title", defaultValue=object );

			if ( ! datamanagerService.isSortable( object ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.objectNotSortable.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			_checkObjectExists( argumentCollection=arguments, object=object );
			_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="edit", object=object );

			prc.records = datamanagerService.getRecordsForSorting( objectName=object );

			_addObjectNameBreadCrumb( event, object );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.sortRecords.breadcrumb.title" )
				, link  = ""
			);
			prc.pageTitle = translateResource( uri="cms:datamanager.sortRecords.title", data=[ objectNamePlural ] );
			prc.pageIcon  = "sort-amount-asc";
		</cfscript>
	</cffunction>

	<cffunction name="sortRecordsAction" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"     required="true" />
		<cfargument name="rc"    type="struct"  required="true" />
		<cfargument name="prc"   type="struct"  required="true" />

		<cfscript>
			var object           = rc.object  ?: "";
			var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var objectNamePlural = translateResource( uri="preside-objects.#object#:title", defaultValue=object );

			if ( ! datamanagerService.isSortable( object ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.objectNotSortable.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}

			_checkObjectExists( argumentCollection=arguments, object=object );
			_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
			_checkPermission( argumentCollection=arguments, key="edit", object=object );

			datamanagerService.saveSortedRecords(
				  objectName = object
				, sortedIds  = ListToArray( rc.ordered ?: "" )
			);

			messageBox.info( translateResource( uri="cms:datamanager.recordsSorted.confirmation", data=[ LCase( objectName ) ] ) );
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
		</cfscript>
	</cffunction>


<!--- VIEWLETS --->
	<cffunction name="versionNavigator" access="private" returntype="string" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />
		<cfargument name="args"  type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			var selectedVersion = Val( args.version ?: "" );

			args.versions = presideObjectService.getRecordVersions(
				  objectName = args.object ?: ""
				, id         = args.id     ?: ""
			);

			if ( !selectedVersion && args.versions.recordCount ) {
				selectedVersion = args.versions._version_number; // first record, they are ordered reverse chronologically
			}

			args.nextVersion = 0;
			args.prevVersion = args.versions.recordCount < 2 ? 0 : args.versions._version_number[ args.versions.recordCount-1 ];

			for( var i=1; i <= args.versions.recordCount; i++ ){
				if ( args.versions._version_number[i] == selectedVersion ) {
					args.nextVersion = i > 1 ? args.versions._version_number[i-1] : 0;
					args.prevVersion = i < args.versions.recordCount ? args.versions._version_number[i+1] : 0;
				}
			}

			return renderView( view="admin/datamanager/versionNavigator", args=args );
		</cfscript>
	</cffunction>

	<cffunction name="translationVersionNavigator" access="private" returntype="string" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />
		<cfargument name="args"  type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			var selectedVersion = Val( args.version ?: "" );
			var translationObjectName = multilingualPresideObjectService.getTranslationObjectName( args.object ?: "" );
			var existingTranslation = multilingualPresideObjectService.selectTranslation(
				  objectName   = args.object ?: ""
				, id           = args.id ?: ""
				, languageId   = args.language ?: ""
				, selectFields = [ "id" ]
			);

			if ( !existingTranslation.recordCount ) {
				return "";
			}

			args.versions = presideObjectService.getRecordVersions(
				  objectName = translationObjectName
				, id         = existingTranslation.id
			);

			if ( !selectedVersion && args.versions.recordCount ) {
				selectedVersion = args.versions._version_number; // first record, they are ordered reverse chronologically
			}

			args.nextVersion = 0;
			args.prevVersion = args.versions.recordCount < 2 ? 0 : args.versions._version_number[ args.versions.recordCount-1 ];

			for( var i=1; i <= args.versions.recordCount; i++ ){
				if ( args.versions._version_number[i] == selectedVersion ) {
					args.nextVersion = i > 1 ? args.versions._version_number[i-1] : 0;
					args.prevVersion = i < args.versions.recordCount ? args.versions._version_number[i+1] : 0;
				}
			}

			return renderView( view="admin/datamanager/translationVersionNavigator", args=args );
		</cfscript>
	</cffunction>

<!--- private events for sharing --->
	<cffunction name="_getObjectRecordsForAjaxDataTables" access="private" returntype="void" output="false">
		<cfargument name="event"               type="any"     required="true" />
		<cfargument name="rc"                  type="struct"  required="true" />
		<cfargument name="prc"                 type="struct"  required="true" />
		<cfargument name="object"              type="string"  required="false" default="#( rc.id ?: '' )#" />
		<cfargument name="gridFields"          type="string"  required="false" default="#( rc.gridFields ?: 'label,datecreated,_version_author' )#" />
		<cfargument name="actionsView"         type="string"  required="false" default="" />
		<cfargument name="filter"              type="struct"  required="false" default="#StructNew()#" />
		<cfargument name="useMultiActions"     type="boolean" required="false" default="true" />
		<cfargument name="isMultilingual"      type="boolean" required="false" default="false" />

		<cfscript>
			gridFields = ListToArray( gridFields );

			var objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var checkboxCol         = [];
			var optionsCol          = [];
			var translateStatusCol  = [];
			var translations        = [];
			var translateUrlBase    = "";
			var dtHelper            = getMyPlugin( "JQueryDatatablesHelpers" );
			var results             = dataManagerService.getRecordsForGridListing(
				  objectName  = object
				, gridFields  = gridFields
				, filter      = arguments.filter
				, startRow    = dtHelper.getStartRow()
				, maxRows     = dtHelper.getMaxRows()
				, orderBy     = dtHelper.getSortOrder()
				, searchQuery = dtHelper.getSearchQuery()
			);
			var records = Duplicate( results.records );
			for( var record in records ){
				for( var field in gridFields ){
					records[ field ][ records.currentRow ] = renderField( object, field, record[ field ], [ "adminDataTable", "admin" ] );
				}

				if ( useMultiActions ) {
					ArrayAppend( checkboxCol, renderView( view="/admin/datamanager/_listingCheckbox", args={ recordId=record.id } ) );
				}

				if ( Len( Trim( actionsView ) ) ) {
					var actionsViewlet = Replace( ReReplace( actionsView, "^/", "" ), "/", ".", "all" );
					var viewletArgs    = Duplicate( record );
					viewletArgs.objectName = object;

					ArrayAppend( optionsCol, renderViewlet( event=actionsViewlet, args=viewletArgs ) );
				} else {
					ArrayAppend( optionsCol, renderView( view="/admin/datamanager/_listingActions", args={
						  viewRecordLink    = event.buildAdminLink( linkto="datamanager.viewRecord", queryString="id=#record.id#&object=#object#" )
						, editRecordLink    = event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#record.id#" )
						, deleteRecordLink  = event.buildAdminLink( linkTo="datamanager.deleteRecordAction", queryString="object=#object#&id=#record.id#" )
						, deleteRecordTitle = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ objectTitleSingular, record[ gridFields[1] ] ] )
						, viewHistoryLink   = event.buildAdminLink( linkTo="datamanager.recordHistory", queryString="object=#object#&id=#record.id#" )
						, canEdit           = datamanagerService.isOperationAllowed( object, "edit"   ) && hasCmsPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ object ] )
						, canDelete         = datamanagerService.isOperationAllowed( object, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] )
						, canViewHistory    = datamanagerService.isOperationAllowed( object, "viewversions" ) && hasCmsPermission( permissionKey="datamanager.viewversions", context="datamanager", contextKeys=[ object ] )
						, objectName        = object
					} ) );
				}

				if ( isMultilingual ) {
					translations     = multilingualPresideObjectService.getTranslationStatus( object, record.id );
					translateUrlBase = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#record.id#&language=" );
					ArrayAppend( translateStatusCol, renderView( view="/admin/datamanager/_listingTranslations", args={
						  translations     = translations
						, translateUrlBase = translateUrlBase
					} ) );
				}
			}

			if ( isMultilingual ) {
				QueryAddColumn( records, "_translateStatus" , translateStatusCol );
				ArrayAppend( gridFields, "_translateStatus" );
			}
			if ( useMultiActions ) {
				QueryAddColumn( records, "_checkbox", checkboxCol );
				ArrayPrepend( gridFields, "_checkbox" );
			}

			QueryAddColumn( records, "_options" , optionsCol );
			ArrayAppend( gridFields, "_options" );

			event.renderData( type="json", data=dtHelper.queryToResult( records, gridFields, results.totalRecords ) );
		</cfscript>
	</cffunction>

	<cffunction name="_getRecordHistoryForAjaxDataTables" access="private" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />
		<cfargument name="object"          type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="recordId"        type="string"  required="false" default="#( rc.id ?: '' )#" />
		<cfargument name="property"        type="string"  required="false" default="#( rc.property ?: '' )#" />
		<cfargument name="gridFields"      type="string"  required="false" default="#( rc.gridFields ?: 'datemodified,label,_version_author' )#" />
		<cfargument name="actionsView"     type="string"  required="false" default="" />

		<cfscript>
			gridFields = ListToArray( gridFields );

			var versionObject       = presideObjectService.getVersionObjectName( object );
			var objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var optionsCol          = [];
			var dtHelper            = getMyPlugin( "JQueryDatatablesHelpers" );
			var results             = dataManagerService.getRecordHistoryForGridListing(
				  objectName  = object
				, recordId    = recordId
				, property    = property
				, gridFields  = gridFields
				, startRow    = dtHelper.getStartRow()
				, maxRows     = dtHelper.getMaxRows()
				, orderBy     = dtHelper.getSortOrder()
				, searchQuery = dtHelper.getSearchQuery()
			);
			var records = Duplicate( results.records );

			for( var record in records ){
				for( var field in gridFields ){
					records[ field ][ records.currentRow ] = renderField( versionObject, field, record[ field ], [ "adminDataTable", "admin" ] );
				}

				if ( Len( Trim( actionsView ) ) ) {
					ArrayAppend( optionsCol, renderView( view=actionsView, args=record ) );
				} else {
					ArrayAppend( optionsCol, renderView( view="/admin/datamanager/_historyActions", args={
						  objectName = object
						, recordId   = recordId
						, editRecordLink = event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#record.id#&version=#record._version_number#" )
					} ) );
				}
			}

			QueryAddColumn( records, "_options" , optionsCol );
			ArrayAppend( gridFields, "_options" );

			event.renderData( type="json", data=dtHelper.queryToResult( records, gridFields, results.totalRecords ) );
		</cfscript>
	</cffunction>

	<cffunction name="_getTranslationRecordHistoryForAjaxDataTables" access="private" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />
		<cfargument name="object"          type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="recordId"        type="string"  required="false" default="#( rc.id ?: '' )#" />
		<cfargument name="languageId"      type="string"  required="false" default="#( rc.language ?: '' )#" />
		<cfargument name="property"        type="string"  required="false" default="#( rc.property ?: '' )#" />
		<cfargument name="gridFields"      type="string"  required="false" default="#( rc.gridFields ?: 'datemodified,label,_version_author' )#" />
		<cfargument name="actionsView"     type="string"  required="false" default="" />

		<cfscript>
			gridFields = ListToArray( gridFields );

			var translationObject   = multilingualPresideObjectService.getTranslationObjectName( object );
			var translationRecord   = multilingualPresideObjectService.selectTranslation(
				  objectName   = object
				, id           = recordId
				, languageId   = languageId
				, selectFields = [ "id" ]
			);
			var versionObject       = presideObjectService.getVersionObjectName( translationObject );
			var objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var optionsCol          = [];
			var dtHelper            = getMyPlugin( "JQueryDatatablesHelpers" );
			var results             = dataManagerService.getRecordHistoryForGridListing(
				  objectName  = translationObject
				, recordId    = translationRecord.id ?: ""
				, property    = property
				, gridFields  = gridFields
				, startRow    = dtHelper.getStartRow()
				, maxRows     = dtHelper.getMaxRows()
				, orderBy     = dtHelper.getSortOrder()
				, searchQuery = dtHelper.getSearchQuery()
				, filter      = { _translation_language = languageId }
			);
			var records = Duplicate( results.records );

			for( var record in records ){
				for( var field in gridFields ){
					records[ field ][ records.currentRow ] = renderField( versionObject, field, record[ field ], [ "adminDataTable", "admin" ] );
				}

				if ( Len( Trim( actionsView ) ) ) {
					ArrayAppend( optionsCol, renderView( view=actionsView, args=record ) );
				} else {
					ArrayAppend( optionsCol, renderView( view="/admin/datamanager/_historyActions", args={
						  objectName = object
						, recordId   = recordId
						, editRecordLink = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#recordId#&language=#languageId#&version=#record._version_number#" )
					} ) );
				}
			}

			QueryAddColumn( records, "_options" , optionsCol );
			ArrayAppend( gridFields, "_options" );

			event.renderData( type="json", data=dtHelper.queryToResult( records, gridFields, results.totalRecords ) );
		</cfscript>
	</cffunction>

	<cffunction name="_addRecordAction" access="private" returntype="any" output="false">
		<cfargument name="event"             type="any"     required="true"  />
		<cfargument name="rc"                type="struct"  required="true"  />
		<cfargument name="prc"               type="struct"  required="true"  />
		<cfargument name="object"            type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="errorAction"       type="string"  required="false" default=""     />
		<cfargument name="viewRecordAction"  type="string"  required="false" default=""     />
		<cfargument name="addAnotherAction"  type="string"  required="false" default=""     />
		<cfargument name="successAction"     type="string"  required="false" default=""     />
		<cfargument name="redirectOnSuccess" type="boolean" required="false" default="true" />
		<cfargument name="formName"          type="string"  required="false" default="preside-objects.#arguments.object#.admin.add" />

		<cfscript>
			var formData         = event.getCollectionForForm( arguments.formName );
			var labelField       = presideObjectService.getObjectAttribute( object, "labelfield", "label" );
			var obj              = "";
			var validationResult = "";
			var newId            = "";
			var newRecordLink    = "";
			var persist          = "";

			validationResult = validateForm( formName=arguments.formName, formData=formData );

			if ( not validationResult.validated() ) {
				messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;
				if ( Len( errorAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=errorAction ), persistStruct=persist );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.addRecord", querystring="object=#object#" ), persistStruct=persist );
				}
			}

			obj = presideObjectService.getObject( object );
			newId = obj.insertData( data=formData, insertManyToManyRecords=true );

			if ( !redirectOnSuccess ) {
				return newId;
			}

			newRecordLink = event.buildAdminLink( linkTo=viewRecordAction ?: "datamanager.viewRecord", queryString="object=#object#&id=#newId#" );

			messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
				  translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object )
				, '<a href="#newRecordLink#">#event.getValue( name=labelField, defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
			] ) );

			if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
				if ( Len( addAnotherAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=addAnotherAction ), persist="_addAnother" );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.addRecord", queryString="object=#object#" ), persist="_addAnother" );
				}
			} else {
				if ( Len( successAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=successAction, queryString="id=#newId#" ) );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#object#" ) );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_addOneToManyRecordAction" access="private" returntype="any" output="false">
		<cfargument name="event"             type="any"     required="true"  />
		<cfargument name="rc"                type="struct"  required="true"  />
		<cfargument name="prc"               type="struct"  required="true"  />
		<cfargument name="object"            type="string"  required="false" default="#( rc.object          ?: '' )#" />
		<cfargument name="parentId"          type="string"  required="false" default="#( rc.parentId        ?: '' )#" />
		<cfargument name="relationshipKey"   type="string"  required="false" default="#( rc.relationshipKey ?: '' )#" />
		<cfargument name="errorAction"       type="string"  required="false" default=""     />
		<cfargument name="viewRecordAction"  type="string"  required="false" default=""     />
		<cfargument name="addAnotherAction"  type="string"  required="false" default=""     />
		<cfargument name="successAction"     type="string"  required="false" default=""     />
		<cfargument name="redirectOnSuccess" type="boolean" required="false" default="true" />
		<cfargument name="formName"          type="string"  required="false" default="preside-objects.#arguments.object#.admin.add" />

		<cfscript>
			var formData         = event.getCollectionForForm( arguments.formName );
			var labelField       = presideObjectService.getObjectAttribute( object, "labelfield", "label" );
			var obj              = "";
			var validationResult = "";
			var newId            = "";
			var newRecordLink    = "";
			var persist          = "";

			formData[ arguments.relationshipKey ] = arguments.parentId;

			validationResult = validateForm( formName=arguments.formName, formData=formData );

			if ( not validationResult.validated() ) {
				messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;
				if ( Len( errorAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=errorAction ), persistStruct=persist );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.addOneToManyRecord", querystring="object=#object#&parentId=#arguments.parentId#&relationshipKey=#arguments.relationshipKey#" ), persistStruct=persist );
				}
			}

			obj = presideObjectService.getObject( object );
			newId = obj.insertData( data=formData, insertManyToManyRecords=true );

			if ( !redirectOnSuccess ) {
				return newId;
			}

			newRecordLink = event.buildAdminLink( linkTo=viewRecordAction ?: "datamanager.viewRecord", queryString="object=#object#&id=#newId#" );

			messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
				  translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object )
				, '<a href="#newRecordLink#">#event.getValue( name=labelField, defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
			] ) );

			if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
				if ( Len( addAnotherAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=addAnotherAction ), persist="_addAnother" );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.addOneToManyRecord", queryString="object=#object#&parentId=#arguments.parentId#&relationshipKey=#arguments.relationshipKey#" ), persist="_addAnother" );
				}
			} else {
				if ( Len( successAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=successAction ) );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.manageOneToManyRecords", queryString="object=#object#&parentId=#arguments.parentId#&relationshipKey=#arguments.relationshipKey#" ) );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_quickAddRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"    type="any"    required="true" />
		<cfargument name="rc"       type="struct" required="true" />
		<cfargument name="prc"      type="struct" required="true" />
		<cfargument name="object"   type="string" required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="formName" type="string" required="false" default="preside-objects.#arguments.object#.admin.quickadd" />

		<cfscript>
			var formData         = event.getCollectionForForm( arguments.formName );
			var validationResult = validateForm( formName=arguments.formName, formData=formData );

			if ( validationResult.validated() ) {
				var obj = presideObjectService.getObject( object );
				var newId = obj.insertData( data=formData, insertManyToManyRecords=true );

				event.renderData( type="json", data={
					  success  = true
					, recordId = newId
				});
			} else {
				event.renderData( type="json", data={
					  success          = false
					, validationResult = translateValidationMessages( validationResult )
				});
			}
		</cfscript>
	</cffunction>

	<cffunction name="_deleteRecordAction" access="private" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />
		<cfargument name="object"            type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="postAction"        type="string"  required="false" default="datamanager.object" />
		<cfargument name="postActionUrl"     type="string"  required="false" default="#( event.buildAdminLink( linkTo=postAction, queryString=( postAction=="datamanager.object" ? "id=#object#" : "" ) ) )#" />
		<cfargument name="redirectOnSuccess" type="boolean" required="false" default="true" />

		<cfscript>
			var id               = rc.id          ?: "";
			var forceDelete      = rc.forceDelete ?: false;
			var ids              = ListToArray( id );
			var obj              = "";
			var records          = "";
			var record           = "";
			var blockers         = "";
			var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var objectNamePlural = translateResource( uri="preside-objects.#object#:title", defaultValue=object );
			var labelField       = presideObjectService.getObjectAttribute( object, "labelfield", "label" );

			obj = presideObjectService.getObject( object );

			records = obj.selectData( selectField=[labelField], filter={ id = ids }, useCache=false );

			if ( records.recordCount neq ids.len() ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[objectName] ) );
				setNextEvent( url=postActionUrl );
			}

			if ( not IsBoolean( forceDelete ) or not forceDelete ) {
				blockers = presideObjectService.listForeignObjectsBlockingDelete( object, ids );

				if ( ArrayLen( blockers ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.cascadeDeletePrompt", queryString="object=#object#&postAction=#postAction#" ), persistStruct={ blockers = blockers, id=ArrayToList(ids) } );
				}
			} else {
				try {
					presideObjectService.deleteRelatedData( objectName=object, recordId=ids );
				} catch( "PresideObjectService.CascadeDeleteTooDeep" e ) {
					messageBox.error( translateResource( uri="cms:datamanager.cascadeDelete.cascade.too.deep.error", data=[objectName] ) );
					setNextEvent( url=postActionUrl );
				}
			}

			if ( presideObjectService.deleteData( objectName=object, filter={ id = ids } ) ) {
				for( record in records ) {
					event.audit(
						  detail   = "#objectName#, '#record[labelField]#', was deleted"
						, source   = "datamanager"
						, action   = "deleteRecord"
						, type     = object
						, instance = record.id
					);
				}

				if ( redirectOnSuccess ) {
					if ( ids.len() eq 1 ) {
						messageBox.info( translateResource( uri="cms:datamanager.recordDeleted.confirmation", data=[ objectName, records[labelField][1] ] ) );
					} else {
						messageBox.info( translateResource( uri="cms:datamanager.recordsDeleted.confirmation", data=[ objectNamePlural, ids.len() ] ) );
					}

					setNextEvent( url=postActionUrl );
				}
			} else {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotDeleted.unknown.error" ) );
				setNextEvent( url=postActionUrl );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_editRecordAction" access="private" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />
		<cfargument name="object"            type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="recordId"          type="string"  required="false" default="#( rc.id     ?: '' )#" />
		<cfargument name="errorAction"       type="string"  required="false" default="" />
		<cfargument name="errorUrl"          type="string"  required="false" default="#( errorAction.len() ? event.buildAdminLink( linkTo=errorAction ) : event.buildAdminLink( linkTo="datamanager.editRecord", querystring="object=#arguments.object#&id=#arguments.recordId#" ) )#" />
		<cfargument name="missingUrl"        type="string"  required="false" default="#event.buildAdminLink( linkTo="datamanager.object", querystring="id=#arguments.object#" )#" />
		<cfargument name="successAction"     type="string"  required="false" default="" />
		<cfargument name="successUrl"        type="string"  required="false" default="#( successAction.len() ? event.buildAdminLink( linkTo=successAction, queryString='id=' & id ) : event.buildAdminLink( linkTo="datamanager.object", querystring="id=#arguments.object#" ) )#" />
		<cfargument name="redirectOnSuccess" type="boolean" required="false" default="true" />
		<cfargument name="formName"          type="string"  required="false" default="preside-objects.#object#.admin.edit" />
		<cfargument name="mergeWithFormName" type="string"  required="false" default="" />

		<cfscript>
			formName = Len( Trim( mergeWithFormName ) ) ? formsService.getMergedFormName( formName, mergeWithFormName ) : formName;

			var id               = rc.id      ?: "";
			var version          = rc.version ?: "";
			var formData         = event.getCollectionForForm( formName );
			var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var obj              = "";
			var validationResult = "";
			var persist          = "";

			if ( not presideObjectService.dataExists( objectName=object, filter={ id=id } ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );

				setNextEvent( url=missingUrl );
			}

			formData.id = id;
			validationResult = validateForm( formName=formName, formData=formData );

			if ( not validationResult.validated() ) {
				messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;

				setNextEvent( url=errorUrl, persistStruct=persist );
			}

			presideObjectService.updateData( objectName=object, data=formData, id=id, updateManyToManyRecords=true );

			if ( redirectOnSuccess ) {
				messageBox.info( translateResource( uri="cms:datamanager.recordEdited.confirmation", data=[ objectName ] ) );

				setNextEvent( url=successUrl );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_quickEditRecordAction" access="private" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />
		<cfargument name="object"            type="string"  required="false" default="#( rc.object ?: '' )#" />

		<cfscript>
			var formName         = "preside-objects.#object#.admin.quickedit";
			var id               = rc.id      ?: "";
			var formData         = event.getCollectionForForm( formName );
			var validationResult = "";

			if ( presideObjectService.dataExists( objectName=object, filter={ id=id } ) ) {
				formData.id = id;
				validationResult = validateForm( formName=formName, formData=formData );

				if ( validationResult.validated() ) {
					presideObjectService.updateData( objectName=object, data=formData, id=id, updateManyToManyRecords=true );
					event.renderData( type="json", data={ success  = true } );
				} else {
					event.renderData( type="json", data={
						  success          = false
						, validationResult = translateValidationMessages( validationResult )
					});
				}

			} else {
				event.renderData( type="json", data={ success = false });
			}
		</cfscript>
	</cffunction>

	<cffunction name="_checkObjectExists" access="public" returntype="void" output="false">
		<cfargument name="event"  type="any"    required="true" />
		<cfargument name="rc"     type="struct" required="true" />
		<cfargument name="prc"    type="struct" required="true" />
		<cfargument name="object" type="string" required="true" />

		<cfscript>
			if ( not presideObjectService.objectExists( object ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.objectNotFound.error", data=[object] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.index" ) );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_checkNavigatePermission" access="public" returntype="void" output="false">
		<cfargument name="event"  type="any"    required="true" />
		<cfargument name="rc"     type="struct" required="true" />
		<cfargument name="prc"    type="struct" required="true" />

		<cfscript>
			if ( !hasCmsPermission( "datamanager.navigate" ) ) {
				event.adminAccessDenied();
			}
		</cfscript>
	</cffunction>

	<cffunction name="_checkPermission" access="public" returntype="void" output="false">
		<cfargument name="event"  type="any"    required="true" />
		<cfargument name="rc"     type="struct" required="true" />
		<cfargument name="prc"    type="struct" required="true" />
		<cfargument name="key"    type="string" required="true" />
		<cfargument name="object" type="string" required="true" />

		<cfscript>
			var operations = [ "add", "edit", "delete", "viewversions" ];
			if ( operations.find( arguments.key ) && !datamanagerService.isOperationAllowed( arguments.object, arguments.key ) ) {
				event.adminAccessDenied();
			}

			if ( !hasCmsPermission( permissionKey="datamanager.#arguments.key#", context="datamanager", contextKeys=[ arguments.object ] ) && !hasCmsPermission( permissionKey="presideobject.#arguments.object#.#arguments.key#" ) ) {
				event.adminAccessDenied();
			}
			var allowedSiteTemplates = presideObjectService.getObjectAttribute( objectName=arguments.object, attributeName="siteTemplates", defaultValue="*" );

			if ( allowedSiteTemplates != "*" && !ListFindNoCase( allowedSiteTemplates, siteService.getActiveSiteTemplate() ) ) {
				event.adminAccessDenied();
			}
		</cfscript>
	</cffunction>

<!--- private utility methods --->
	<cffunction name="_getObjectFieldsForGrid" access="private" returntype="array" output="false">
		<cfargument name="objectName" type="string" required="true" />

		<cfreturn dataManagerService.listGridFields( arguments.objectName ) />
	</cffunction>

	<cffunction name="_addObjectNameBreadCrumb" access="private" returntype="void" output="false">
		<cfargument name="event"         type="any"    required="true" />
		<cfargument name="objectName" type="string" required="true" />

		<cfscript>
			event.addAdminBreadCrumb(
				  title = translateResource( "preside-objects.#objectName#:title" )
				, link  = event.buildAdminLink( linkTo="datamanager.object", querystring="id=#objectName#" )
			);
		</cfscript>
	</cffunction>

	<cffunction name="_objectCanBeViewedInDataManager" access="private" returntype="boolean" output="false">
		<cfargument name="event"              type="any"     required="true" />
		<cfargument name="objectName"         type="string"  required="true" />
		<cfargument name="relocateIfNoAccess" type="boolean" required="false" default="false" />

		<cfscript>
			if ( dataManagerService.isObjectAvailableInDataManager( arguments.objectName ) ) {
				return true;
			}

			if ( arguments.relocateIfNoAccess ) {
				messageBox.error( translateResource( uri="cms:datamanager.objectNotManagedByManager.error", data=[ objectName ] ) );
				setNextEvent(
					url = event.buildAdminLink( "datamanager" )
				);
			}
			return false;
		</cfscript>
	</cffunction>

	<cffunction name="_getParentDetailsForOneToManyActions" access="private" returntype="struct" output="false">
		<cfargument name="event"  type="any"    required="true" />
		<cfargument name="rc"     type="struct" required="true" />
		<cfargument name="prc"    type="struct" required="true" />

		<cfscript>
			var object          = rc.object          ?: "";
			var parentId        = rc.parentId        ?: "";
			var relationshipKey = rc.relationshipKey ?: "";
			var parentObject    = presideObjectService.getObjectPropertyAttribute(
				  objectName    = object
				, propertyName  = relationshipKey
				, attributeName = "relatedTo"
			);
			var parentRecord      = presideObjectService.selectData( objectName=parentObject, id=parentId, selectFields=[ "${labelfield} as label" ] );
			var parentObjectTitle = "";

			if ( presideObjectService.isPageType( parentObject ) ) {
				parentObjectTitle = translateResource( "page-types.#parentObject#:name" );
			} else {
				parentObjectTitle = translateResource( "preside-objects.#parentObject#:title.singular" );
			}

			return {
				  parentObject      = parentObject
				, parentRecordLabel = parentRecord.label ?: ""
				, parentObjectTitle = parentObjectTitle
			};
		</cfscript>
	</cffunction>

</cfcomponent>