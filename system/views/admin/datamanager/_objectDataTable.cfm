<cfscript>
	param name="args.objectName"          type="string";
	param name="args.multiActions"        type="string"  default="";
	param name="args.useMultiActions"     type="boolean" default=false;
	param name="args.multiActionViewlet"  type="string"  default="admin.datamanager._multiActions";
	param name="args.multiActionUrl"      type="string"  default="";
	param name="args.isMultilingual"      type="boolean" default=false;
	param name="args.draftsEnabled"       type="boolean" default=false;
	param name="args.noActions"           type="boolean" default=false;
	param name="args.footerEnabled"       type="boolean" default=false;
	param name="args.gridFields"          type="array";
	param name="args.sortableFields"      type="array"   default=[];
	param name="args.hiddenGridFields"    type="array"   default=[];
	param name="args.filterContextData"   type="struct"  default={};
	param name="args.allowSearch"         type="boolean" default=true;
	param name="args.allowFilter"         type="boolean" default=true;
	param name="args.allowDataExport"     type="boolean" default=false;
	param name="args.clickableRows"       type="boolean" default=true;
	param name="args.compact"             type="boolean" default=false;
	param name="args.batchEditableFields" type="array"   default=[];
	param name="args.datasourceUrl"       type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="ajaxListing", args={ useMultiActions=args.useMultiActions, gridFields=ListAppend( ArrayToList( args.gridFields ), ArrayToList( args.hiddenGridFields ) ), isMultilingual=args.isMultilingual, draftsEnabled=args.draftsEnabled, noActions=args.noActions } );
	param name="args.exportFilterString"  type="string"  default="";
	param name="args.dataExportUrl"       type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="exportDataAction"      );
	param name="args.dataExportConfigUrl" type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="dataExportConfigModal" );
	param name="args.saveExportUrl"       type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="saveExportAction"      );
	param name="args.noRecordMessage"     type="string"  default=translateResource( uri="cms:datatables.emptyTable" );
	param name="args.objectTitlePlural"   type="string"  default=translateObjectName( objectName=args.objectName, plural=true );
	param name="args.excludeFilterExpressionTags" type="string"  default="";

	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ args.objectTitlePlural ] );
	batchEditTitle       = translateResource( uri="cms:datamanager.batchEditSelected.title" );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");

	instanceId = LCase( Hash( CallStackGet( "string" ) ) );
	tableId = args.id ?: "object-listing-table-#LCase( args.objectName )#-#instanceId#";

	args.allowFilter  = IsTrue( args.allowFilter ?: "" );

	if ( args.allowFilter ) {
		favourites = renderViewlet( event="admin.rulesEngine.dataGridFavourites", args={ objectName=args.objectName } );

		allowUseFilter    = IsTrue( args.allowUseFilter    ?: true );
		allowManageFilter = IsTrue( args.allowManageFilter ?: true );
		manageFilterLink  = args.manageFilterLink ?: "";

		if ( allowManageFilter ) {
			saveFilterFormEndpoint = event.buildAdminLink(
				  linkTo      = "rulesEngine.superQuickAddFilterForm"
				, querystring = "filter_object=#args.objectName#&multiple=false&expressions="
			);
		}
	}

	allowDataExport  = args.allowDataExport && isFeatureEnabled( "dataexport" );
	allowSaveExport  = allowDataExport && isFeatureEnabled( "dataexport" );
	savedExportCount = Val( args.savedExportCount ?: "" );
	savedExportsLink = args.savedExportsLink ?: "";

	if ( args.footerEnabled ) {
		colCount = ArrayLen( args.gridFields );
		if ( args.useMultiActions ) {
			colCount++;
		}
		if ( args.draftsEnabled ) {
			colCount++;
		}
		if ( args.isMultilingual ) {
			colCount++;
		}
		if ( !args.noActions ) {
			colCount++;
		}
	}
</cfscript>
<cfoutput>
	<div class="table-responsive<cfif args.compact> table-compact</cfif>" id="#tableId#-container">
		<cfif allowDataExport>
			<form action="#args.dataExportUrl#" method="post" class="hide object-listing-table-export-form">
				<input name="object" value="#args.objectName#" type="hidden">
				<input name="exportFilterString" value="#htmlEditFormat( args.exportFilterString )#" type="hidden">
			</form>
		</cfif>
		<cfif allowSaveExport>
			<form action="#args.saveExportUrl#" method="post" class="hide object-listing-table-save-export-form">
				<input name="object" value="#args.objectName#" type="hidden">
				<input name="exportFilterString" value="#htmlEditFormat( args.exportFilterString )#" type="hidden">
			</form>
		</cfif>
		<cfif args.useMultiActions>
			<form id="multi-action-form-#instanceId#" class="form-horizontal multi-action-form" method="post" action="#args.multiActionUrl#">
				<input type="hidden" name="multiAction" value="" />
		</cfif>

		<cfif args.allowFilter>
			<cfif allowUseFilter>
				<div class="object-listing-table-filter hide" id="#tableId#-filter" data-allow-manage-filter="#booleanFormat( allowManageFilter )#" data-allow-use-filter="#booleanFormat( allowUseFilter )#" data-manage-filters-link="#manageFilterLink#">
					<div id="quick-filter-form-#instanceId#" class="in clearfix">
						#renderFormControl(
							  name        = "filter"
							, id          = "filter-#instanceId#"
							, type        = "rulesEngineFilterBuilder"
							, context     = "admin"
							, contextData = args.filterContextData
							, excludeTags = args.excludeFilterExpressionTags
							, object      = args.objectName
							, label       = ""
							, layout      = ""
							, compact     = true
							, showCount   = false
						)#

						<cfif allowManageFilter>
							<div class="form-actions">
								<div class="pull-right">
									<button class="btn btn-info btn-sm save-filter-btn" tabindex="#getNextTabIndex()#" disabled data-save-form-endpoint="#saveFilterFormEndpoint#" data-modal-dialog-full="true">
										<i class="fa fa-fw fa-save"></i>
										#translateResource( "cms:rulesEngine.quick.filter.save.btn" )#
									</button>
								</div>
							</div>
						</cfif>
					</div>
				</div>
			</cfif>

			<div class="object-listing-table-favourites hide" id="#tableId#-favourites">
				#favourites#
			</div>
		</cfif>

		<cfif allowDataExport>
			<div class="object-listing-table-export hide">
				<div class="pull-left">
					<cfif savedExportCount>
						<a href="#savedExportsLink#">
							<i class="fa fa-fw fa-save"></i>
							#translateResource( uri="cms:savedexports.for.object.link", data=[ NumberFormat( savedExportCount ) ] )#
						</a>
					</cfif>
					&nbsp;
					<a class="btn btn-info btn-sm object-listing-data-export-button" href="#args.dataExportConfigUrl#">
						<i class="fa fa-fw fa-download"></i>
						#translateResource( "cms:datatable.export.btn" )#
					</a>
				</div>
			</div>
		</cfif>

		<table id="#tableId#" class="table table-hover object-listing-table"
			data-object-name="#args.objectName#"
			data-object-title="#args.objectTitlePlural#"
		    data-datasource-url="#args.datasourceUrl#"
		    data-use-multi-actions="#args.useMultiActions#"
		    data-allow-search="#args.allowSearch#"
		    data-allow-data-export="#allowDataExport#"
		    data-allow-save-export="#allowSaveExport#"
		    data-is-multilingual="#args.isMultilingual#"
		    data-drafts-enabled="#args.draftsEnabled#"
		    data-clickable-rows="#args.clickableRows#"
		    data-no-actions="#args.noActions#"
		    data-allow-filter="#args.allowFilter#"
		    data-compact="#args.compact#"
		    data-no-record-message="#args.noRecordMessage#"
		>
			<thead>
				<tr>
					<cfif args.useMultiActions>
						<th class="center">
							<label>
								<input type="checkbox" class="ace" />
								<span class="lbl"></span>
							</label>
						</th>
					</cfif>
					<cfloop array="#args.gridFields#" index="fieldName">
						<th class="<cfif !isEmpty( args.sortableFields ) and !arrayContains( args.sortableFields, fieldName )>no-sorting</cfif>" data-field="#ListLast( fieldName, '.' )#">
							#translatePropertyName( args.objectName, fieldName, "listing" )#

							<cfset help = translateResource( uri=getResourceBundleUriRoot( args.objectName ) & "field.#fieldName#.listing.help", defaultValue="" ) />

							<cfif !isEmpty( help )>
								<span class="help-button fa fa-question" data-rel="popover" data-trigger="hover" data-placement="top" data-content="#htmlEditFormat( help )#" title="#translateResource( 'cms:help.popover.title' )#"></span>
							</cfif>
						</th>
					</cfloop>
					<cfif args.draftsEnabled>
						<th>#translateResource( uri="cms:datamanager.column.draft.status" )#</th>
					</cfif>
					<cfif args.isMultilingual>
						<th>#translateResource( uri="cms:datamanager.translate.column.status" )#</th>
					</cfif>
					<cfif !args.noActions>
						<th>&nbsp;</th>
					</cfif>
				</tr>
			</thead>
			<cfif args.footerEnabled>
				<tfoot>
					<tr>
						<th colspan="#colCount#"></th>
					</tr>
				</tfoot>
			</cfif>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr<cfif args.useMultiActions> > td :checkbox<cfelse> a:nth-of-type(1)</cfif>">
			</tbody>
		</table>
		<cfif args.useMultiActions>
				<div class="form-actions multi-action-buttons" id="multi-action-buttons-#instanceId#">
					<cfif Len( Trim( args.multiActions ) )>
						#args.multiActions#
					<cfelse>
						#renderViewlet( event=args.multiActionViewlet, args=args )#
					</cfif>
				</div>
			</form>
		</cfif>
	</div>
</cfoutput>