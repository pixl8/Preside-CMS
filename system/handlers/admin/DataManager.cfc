<cfcomponent output="false" extends="preside.system.base.AdminHandler">

	<cfproperty name="presideObjectService" inject="presideObjectService"        />
	<cfproperty name="dataManagerService"   inject="dataManagerService" />
	<cfproperty name="formsService"         inject="formsService"                />
	<cfproperty name="validationEngine"     inject="validationEngine"            />
	<cfproperty name="messageBox"           inject="coldbox:plugin:messageBox"   />

	<cffunction name="preHandler" access="public" returntype="void" output="false">
		<cfargument name="event"          type="any"    required="true" />
		<cfargument name="action"         type="string" required="true" />
		<cfargument name="eventArguments" type="struct" required="true" />

		<cfscript>
			super.preHandler( argumentCollection = arguments );

			if ( !hasPermission( "datamanager.navigate" ) ) {
				event.adminAccessDenied();
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
			prc.objectGroups = dataManagerService.getGroupedObjects();
		</cfscript>
	</cffunction>

	<cffunction name="object" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = event.getValue( name="id", default="" );

			if ( !hasPermission( permissionKey="datamanager.navigate", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

			_checkObjectExists( argumentCollection=arguments, object=objectName );

			_objectCanBeViewedInDataManager( event=event, objectName=objectName, relocateIfNoAccess=true );

			_addObjectNameBreadCrumb( event, objectName );

			prc.gridFields = _getObjectFieldsForGrid( objectName );
		</cfscript>
	</cffunction>

	<cffunction name="getObjectRecordsForAjaxDataTables" access="public" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />

		<cfscript>
			var objectName = rc.id ?: "";

			if ( !hasPermission( permissionKey="datamanager.navigate", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

			runEvent(
				  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object          = objectName
					, useMultiActions = hasPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] )
					, gridFields      = ( rc.gridFields ?: 'label,datecreated,datemodified' )
				}
			);
		</cfscript>
	</cffunction>

	<cffunction name="getObjectRecordsForAjaxSelectControl" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var records = dataManagerService.getRecordsForAjaxSelect(
				  objectName  = rc.object  ?: ""
				, maxRows     = rc.maxRows ?: 1000
				, searchQuery = rc.q       ?: ""
				, ids         = ListToArray( rc.values ?: "" )
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

			if ( !hasPermission( permissionKey="datamanager.manageContextPerms", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

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

			if ( !hasPermission( permissionKey="datamanager.manageContextPerms", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

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
			if ( !hasPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

			// temporary redirect to edit record (we haven't implemented view record yet!)
			setNextEvent( url=event.buildAdminLink( linkTo="datamanager.editRecord", queryString="id=#recordId#&object=#objectName#" ) );
		</cfscript>
	</cffunction>

	<cffunction name="deleteRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />
		<cfargument name="object"            type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="postAction"        type="string"  required="false" default="datamanager.object" />
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
			var postActionUrl    = event.buildAdminLink( linkTo=postAction, queryString=( postAction=="datamanager.object" ? "id=#object#" : "" ) );

			_checkObjectExists( argumentCollection=arguments, object=object );
			if ( !hasPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] ) ) {
				event.adminAccessDenied();
			}

			obj = presideObjectService.getObject( object );

			records = obj.selectData( selectField=['label'], filter={ id = ids }, useCache=false );

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
						  detail   = "#objectName#, '#record.label#', was deleted"
						, source   = "datamanager"
						, action   = "deleteRecord"
						, type     = object
						, instance = record.id
					);
				}

				if ( redirectOnSuccess ) {
					if ( ids.len() eq 1 ) {
						messageBox.info( translateResource( uri="cms:datamanager.recordDeleted.confirmation", data=[ objectName, records.label ] ) );
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

	<cffunction name="cascadeDeletePrompt" access="public" returntype="void" output="false">
		<cfargument name="event" type="any"    required="true" />
		<cfargument name="rc"    type="struct" required="true" />
		<cfargument name="prc"   type="struct" required="true" />

		<cfscript>
			var objectName = rc.object ?: "";

			_checkObjectExists( argumentCollection=arguments, object=objectName );
			if ( !hasPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

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

			if ( !hasPermission( permissionKey="datamanager.add", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

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
			if ( !hasPermission( permissionKey="datamanager.add", context="datamanager", contextKeys=[ objectName ] ) ) {
				event.adminAccessDenied();
			}

			runEvent(
				  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
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
			var object     = rc.object ?: "";
			var id         = rc.id     ?: "";
			var objectName = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var record     = "";

			_checkObjectExists( argumentCollection=arguments, object=object );
			_objectCanBeViewedInDataManager( event=event, objectName=object, relocateIfNoAccess=true );
			if ( !hasPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ object ] ) ) {
				event.adminAccessDenied();
			}

			// validity checks
			if ( not presideObjectService.objectExists( object ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.objectNotFound.error", data=[object] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.index" ) );
			}

			prc.useVersioning = presideObjectService.objectIsVersioned( object );
			prc.record = presideObjectService.selectData( objectName=object, filter={ id=id }, useCache=false );
			if ( not prc.record.recordCount ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );
				setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
			}
			prc.record = queryRowToStruct( prc.record );

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
		<cfargument name="object"            type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="errorAction"       type="string"  required="false" default="" />
		<cfargument name="successAction"     type="string"  required="false" default="" />
		<cfargument name="redirectOnSuccess" type="boolean" required="false" default="true" />
		<cfargument name="formName"          type="string"  required="false" default="preside-objects.#object#.admin.edit" />
		<cfargument name="mergeWithFormName" type="string"  required="false" default="" />

		<cfscript>
			formName = Len( Trim( mergeWithFormName ) ) ? formsService.getMergedFormName( formName, mergeWithFormName ) : formName;

			var id               = event.getValue( name="id", defaultValue="" );
			var formData         = event.getCollectionForForm( formName );
			var objectName       = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var obj              = "";
			var validationResult = "";
			var persist          = "";

			_checkObjectExists( argumentCollection=arguments, object=object );
			if ( !hasPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ object ] ) ) {
				event.adminAccessDenied();
			}

			if ( not presideObjectService.dataExists( objectName=object, filter={ id=id } ) ) {
				messageBox.error( translateResource( uri="cms:datamanager.recordNotFound.error", data=[ LCase( objectName ) ] ) );

				if ( Len( errorAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=errorAction ) );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ) );
				}
			}

			formData.id = id;
			validationResult = validateForm( formName=formName, formData=formData );

			if ( not validationResult.validated() ) {
				messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
				persist = formData;
				persist.validationResult = validationResult;

				if ( Len( errorAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=errorAction ), persistStruct=persist );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", querystring="id=#object#" ), persistStruct=persist );
				}
			}

			presideObjectService.updateData( objectName=object, data=formData, id=id, updateManyToManyRecords=true );

			if ( redirectOnSuccess ) {
				messageBox.info( translateResource( uri="cms:datamanager.recordEdited.confirmation", data=[ objectName ] ) );

				if ( Len( successAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=successAction, queryString="id=#id#" ) );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.viewRecord", queryString="object=#object#&id=#id#" ) );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="multiRecordAction" access="public" returntype="void" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />

		<cfscript>
			var object     = rc.object      ?: ""
			var action     = rc.multiAction ?: ""
			var ids        = rc.id          ?: ""
			var listingUrl = event.buildAdminLink( linkTo=rc.postAction ?: "datamanager.object", queryString="id=#object#" );

			_checkObjectExists( argumentCollection=arguments, object=object );

			if ( not Len( Trim( ids ) ) ) {
				messageBox.error( translateResource( "cms:datamanager.norecordsselected.error" ) );
				setNextEvent( url=listingUrl );
			}

			switch( action ){
				case "delete":
					return deleteRecordAction( argumentCollection = arguments );
				break;
			}

			messageBox.error( translateResource( "cms:datamanager.invalid.multirecord.action.error" ) );
			setNextEvent( url=listingUrl );
		</cfscript>
	</cffunction>

<!--- private events for sharing --->
	<cffunction name="_getObjectRecordsForAjaxDataTables" access="private" returntype="void" output="false">
		<cfargument name="event"           type="any"     required="true" />
		<cfargument name="rc"              type="struct"  required="true" />
		<cfargument name="prc"             type="struct"  required="true" />
		<cfargument name="object"          type="string"  required="false" default="#( rc.id ?: '' )#" />
		<cfargument name="gridFields"      type="string"  required="false" default="#( rc.gridFields ?: 'label,datecreated,datemodified' )#" />
		<cfargument name="actionsView"     type="string"  required="false" default="" />
		<cfargument name="useMultiActions" type="boolean" required="false" default="true" />

		<cfscript>
			gridFields = ListToArray( gridFields );

			var objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
			var checkboxCol         = [];
			var optionsCol          = [];
			var dtHelper            = getMyPlugin( "JQueryDatatablesHelpers" );
			var results             = dataManagerService.getRecordsForGridListing(
				  objectName  = object
				, gridFields  = gridFields
				, startRow    = dtHelper.getStartRow()
				, maxRows     = dtHelper.getMaxRows()
				, orderBy     = dtHelper.getSortOrder()
				, searchQuery = dtHelper.getSearchQuery()
			);
			var records = Duplicate( results.records );

			for( var record in records ){
				for( var field in gridFields ){
					records[ field ][ records.currentRow ] = renderField( object, field, record[ field ], "adminDataTable" );
				}

				if ( useMultiActions ) {
					ArrayAppend( checkboxCol, renderView( view="/admin/datamanager/_listingCheckbox", args={ recordId=record.id } ) );
				}

				if ( Len( Trim( actionsView ) ) ) {
					ArrayAppend( optionsCol, renderView( view=actionsView, args=record ) );
				} else {
					ArrayAppend( optionsCol, renderView( view="/admin/datamanager/_listingActions", args={
						  viewRecordLink    = event.buildAdminLink( linkto="datamanager.viewRecord", queryString="id=#record.id#&object=#object#" )
						, editRecordLink    = event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#record.id#" )
						, deleteRecordLink  = event.buildAdminLink( linkTo="datamanager.deleteRecordAction", queryString="object=#object#&id=#record.id#" )
						, deleteRecordTitle = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ objectTitleSingular, record[ gridFields[1] ] ] )
						, objectName        = object
					} ) );
				}
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

	<cffunction name="_addRecordAction" access="private" returntype="any" output="false">
		<cfargument name="event"             type="any"     required="true" />
		<cfargument name="rc"                type="struct"  required="true" />
		<cfargument name="prc"               type="struct"  required="true" />
		<cfargument name="object"            type="string"  required="false" default="#( rc.object ?: '' )#" />
		<cfargument name="errorAction"       type="string"  required="false" default="" />
		<cfargument name="viewRecordAction"  type="string"  required="false" default="" />
		<cfargument name="addAnotherAction"  type="string"  required="false" default="" />
		<cfargument name="successAction"     type="string"  required="false" default="" />
		<cfargument name="redirectOnSuccess" type="boolean" required="false" default="true" />

		<cfscript>
			var formName         = "preside-objects.#object#.admin.add";
			var formData         = event.getCollectionForForm( formName );
			var obj              = "";
			var validationResult = "";
			var newId            = "";
			var newRecordLink    = "";
			var persist          = "";

			validationResult = validateForm( formName=formName, formData=formData );

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
				, '<a href="#newRecordLink#">#event.getValue( name="label", defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
			] ) );

			if ( Val( event.getValue( name="_addanother", defaultValue=0 ) ) ) {
				if ( Len( addAnotherAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=addAnotherAction ), persist="_addAnother" );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.addRecord", queryString="object=#object#" ), persist="_addAnother" );
				}
			} else {
				if ( Len( addAnotherAction ?: "" ) ) {
					setNextEvent( url=event.buildAdminLink( linkTo=successAction ) );
				} else {
					setNextEvent( url=event.buildAdminLink( linkTo="datamanager.object", queryString="id=#object#" ) );
				}
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

</cfcomponent>