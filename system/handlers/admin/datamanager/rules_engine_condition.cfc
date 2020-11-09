component {
	property name="rulesEngineFilterService"  inject="RulesEngineFilterService";
	property name="rulesEngineContextService" inject="rulesEngineContextService";

	private void function preAddRecordAction( event, rc, prc, args={} ){
		if ( !args.validationResult.validated() ) {
			args.formData.delete( "context" );
		}
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		if ( event.isDataManagerRequest() && event.getCurrentAction() == "manageFilters" ) {
			return "filterobject=" & ( prc.objectName ?: "" );
		}

		return "";
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters ?: [];

		rulesEngineFilterService.getRulesEngineSelectArgsForEdit( args=args );

		var filterObject = rc.filterObject ?: "";
		if ( Len( filterObject ) ) {
			ArrayAppend( args.extraFilters, { filter = {
				filter_object = filterObject
			} } );
		}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		switch ( args.formData.filter_sharing_scope ?: "" ) {
			case "global":
				args.formData.owner            = "";
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
			case "individual":
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
		}
	}

	private array function getRecordActionsForGridListing( event, rc, prc, args={} ) {
		var record    = args.record ?: {};
		var recordId  = record.id   ?: "";
		var kind      = record.kind ?: "";
		var actions   = [];
		var canEdit   = true;
		var canDelete = true;

		if ( kind == "filter" ) {
			canEdit = canDelete = runEvent(
				  event = "admin.datamanager._checkPermission"
				, private = true
				, prepostExempt = true
				, eventArguments = {
					  key          = "manageFilters"
					, object       = record.filter_object ?: ""
					, throwOnError = false
				  }
			);

			canDelete = canDelete && !rulesEngineFilterService.filterIsUsed( recordId );
		} else {
			canEdit   = hasCmsPermission( "rulesengine.edit" );
			canDelete = hasCmsPermission( "rulesengine.delete" );
		}

		if ( canEdit ) {
			ArrayAppend( actions, {
				  link       = event.buildAdminLink( objectName="rules_engine_condition", recordId=recordId, operation="editRecord" )
				, icon       = "fa-pencil"
				, contextKey = "e"
			} );
		}

		if ( canDelete ) {
			ArrayAppend( actions, {
				  link       = event.buildAdminLink( objectName="rules_engine_condition", recordId=recordId, operation="deleteRecordAction" )
				, icon       = "fa-trash-o"
				, contextKey = "d"
				, class      = "confirmation-prompt"
				, title      = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ translateResource( "preside-objects.rules_engine_condition:title.singular" ), record.condition_name ] )
			} );
		} else {
			ArrayAppend( actions, {
				  link = "##"
				, icon = "fa-trash-o light-grey disabled"
			} );
		}

		return actions;
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var qs = "id=#( args.recordId ?: '' )#";

		if ( Len( args.queryString ?: "" ) ) {
			qs &= "&#args.queryString#";
		}

		return event.buildAdminLink( linkto="rulesengine.editCondition", queryString=qs );
	}

	private string function buildDeleteRecordActionLink( event, rc, prc, args={} ) {
		var qs = "id=#( args.recordId ?: '' )#";

		if ( Len( args.queryString ?: "" ) ) {
			qs &= "&#args.queryString#";
		}

		return event.buildAdminLink( linkto="rulesengine.deleteConditionAction", queryString=qs );
	}

	private array function getTopRightButtonsForObject( event, rc, prc, args={} ) {
		var actions = [];

		event.include( "/css/admin/specific/rulesengine/index/" );

		if ( IsTrue( prc.canAdd ?: "" ) ) {
			var contexts = rulesEngineContextService.listContexts();

			if ( ArrayLen( contexts ) ) {
				var children = [];

				for( var context in contexts ) {
					ArrayAppend( children, {
						  link  = event.buildAdminLink( objectName="rules_engine_condition", operation="addRecord", queryString='context=' & context.id )
						, title = '<p class="title"><i class="fa fa-fw #context.iconClass#"></i>&nbsp; #context.title#</p> <p class="description"><em class="light-grey">#context.description#</em></p>'
					} );
				}

				ArrayAppend( actions, {
					  title     = translateResource( 'cms:rulesEngine.add.condition.btn' )
					, btnClass  = "btn-success"
					, iconClass = "fa-plus"
					, children  = children
				} );
			}
		}

		return actions;
	}

	/*
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "rulesEngine.add" )>
			<button data-toggle="dropdown" class="btn btn-sm btn-success pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-plus"></i>&nbsp; #translateResource( 'cms:rulesEngine.add.condition.btn')#
			</button>

			<ul class="dropdown-menu pull-right dropdown-caret dropdown-caret-right" role="menu" aria-labelledby="label">
				<cfloop array="#contexts#" item="context" index="i">
					<li>
						<a href="#event.buildAdminLink( linkTo='rulesEngine.addCondition', queryString='context=' & context.id )#">
							<p class="title"><i class="fa fa-fw #context.iconClass#"></i>&nbsp; #context.title#</p>
							<p class="description"><em class="light-grey">#context.description#</em></p>
						</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
	</div>
	*/
}