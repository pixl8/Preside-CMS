<!---@feature admin--->
<cfscript>
	param name="args.objectName"                  type="string";
	param name="args.multiActions"                type="string"  default="";
	param name="args.useMultiActions"             type="boolean" default=false;
	param name="args.multiActionViewlet"          type="string"  default="admin.datamanager._multiActions";
	param name="args.multiActionUrl"              type="string"  default="";
	param name="args.isMultilingual"              type="boolean" default=false;
	param name="args.draftsEnabled"               type="boolean" default=false;
	param name="args.noActions"                   type="boolean" default=false;
	param name="args.footerEnabled"               type="boolean" default=false;
	param name="args.footerWrapWithRow"           type="boolean" default=true;
	param name="args.gridFields"                  type="array";
	param name="args.gridHeaderLabels"            type="struct"  default={};
	param name="args.sortableFields"              type="array"   default=[];
	param name="args.centerAlignFields"           type="array"   default=[];
	param name="args.rightAlignFields"            type="array"   default=[];
	param name="args.hiddenGridFields"            type="array"   default=[];
	param name="args.filterContextData"           type="struct"  default={};
	param name="args.allowSearch"                 type="boolean" default=true;
	param name="args.allowFilter"                 type="boolean" default=true;
	param name="args.allowDataExport"             type="boolean" default=false;
	param name="args.allowSaveExport"             type="boolean" default=true;
	param name="args.allowColumnPicker"           type="boolean" default=true;
	param name="args.clickableRows"               type="boolean" default=true;
	param name="args.compact"                     type="boolean" default=false;
	param name="args.batchEditableFields"         type="array"   default=[];
	param name="args.listingPreferenceKey"        type="string"  default="#args.objectName#";
	param name="args.datasourceUrl"               type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="ajaxListing", args={ useMultiActions=args.useMultiActions, gridFields=ListAppend( ArrayToList( args.gridFields ), ArrayToList( args.hiddenGridFields ) ), isMultilingual=args.isMultilingual, draftsEnabled=args.draftsEnabled, noActions=args.noActions } );
	param name="args.exportFilterString"          type="string"  default="";
	param name="args.dataExportUrl"               type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="exportDataAction"      );
	param name="args.exportTemplate"              type="string"  default="";
	param name="args.customExportUrl"             type="string"  default="";
	param name="args.dataExportConfigUrl"         type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="dataExportConfigModal", queryString="exportTemplate=#args.exportTemplate#" );
	param name="args.saveExportUrl"               type="string"  default=event.buildAdminLink( objectName=args.objectName, operation="saveExportAction" );
	param name="args.saveListingColumnsUrl"       type="string"  default=event.buildAdminLink( linkTo="datamanager.saveListingColumns" );
	param name="args.objectTitlePlural"           type="string"  default=translateObjectName( objectName=args.objectName, plural=true );
	param name="args.excludeFilterExpressionTags" type="string"  default="";
	param name="args.noRecordMessage"             type="string"  default=translateResource( uri="cms:datatables.emptyTable" );
	param name="args.noRecordTableHide"           type="boolean" default=false;
	param name="args.noRecordTableHideMessage"    type="string"  default="";

	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ args.objectTitlePlural ] );
	batchEditTitle       = translateResource( uri="cms:datamanager.batchEditSelected.title" );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");
	event.includeData( {
		  defaultPageLength = args.defaultPageLength ?: getSetting( name="datamanager.defaults.datatable.defaultPageLength", defaultValue=10 )
		, paginationOptions = args.paginationOptions ?: getSetting( name="datamanager.defaults.datatable.paginationOptions", defaultValue=[ 5, 10, 25, 50, 100 ] )
	} );

	instanceId = LCase( Hash( serializeJSON( args.filterContextData ) & CallStackGet( "string" ) & args.datasourceUrl ) );
	tableId = args.id ?: "object-listing-table-#LCase( args.objectName )#-#instanceId#";

	args.allowFilter  = IsTrue( args.allowFilter ?: "" ) && isFeatureEnabled( "rulesEngine" );

	allowUseFilter    = false;
	allowManageFilter = false;
	manageFilterLink  = args.manageFilterLink ?: "";
	favourites        = "";

	if ( args.allowFilter ) {
		favourites = renderViewlet( event="admin.rulesEngine.dataGridFavourites", args={ objectName=args.objectName } );

		allowUseFilter    = IsTrue( args.allowUseFilter    ?: true );
		allowManageFilter = IsTrue( args.allowManageFilter ?: true );

		if ( allowManageFilter ) {
			saveFilterFormEndpoint = event.buildAdminLink(
				  linkTo      = "rulesEngine.superQuickAddFilterForm"
				, querystring = "filter_object=#args.objectName#&multiple=false&expressions="
			);
		}
	}

	allowDataExport  = args.allowDataExport && isFeatureEnabled( "dataexport" );
	allowSaveExport  = args.allowSaveExport && allowDataExport;
	savedExportCount = Val( args.savedExportCount ?: "" );
	savedExportsLink = args.savedExportsLink ?: "";
	allowColumnPicker = IsTrue( args.allowColumnPicker ?: true );

	toolbarConfig = getSingleton( "dataListingPreferencesService" ).getToolbarConfig(
		  objectName         = args.objectName
		, listingKey         = args.listingPreferenceKey
		, gridFields         = args.gridFields
		, hiddenGridFields   = args.hiddenGridFields
		, allowFilter        = args.allowFilter && allowUseFilter
		, allowSearch        = args.allowSearch
		, allowManageFilter  = allowManageFilter
		, manageFilterLink   = manageFilterLink
	);

	if ( args.footerEnabled ) {
		headerFieldCount = ArrayLen( toolbarConfig.columns ?: [] );
		if ( !headerFieldCount ) {
			headerFieldCount = ArrayLen( args.gridFields );
		} else if ( !allowColumnPicker ) {
			headerFieldCount = 0;
			for( var listingCol in toolbarConfig.columns ) {
				if ( IsTrue( listingCol.visible ?: true ) ) {
					headerFieldCount++;
				}
			}
		}
		colCount = headerFieldCount;
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
	<div class="table-responsive object-listing-wrap<cfif args.compact> table-compact</cfif>" id="#tableId#-container">
		<cfif allowDataExport>
			<form action="#args.dataExportUrl#" method="post" class="hide object-listing-table-export-form">
				<input name="object" value="#args.objectName#" type="hidden">
				<input name="exportFilterString" value="#HtmlEditFormat( args.exportFilterString )#" type="hidden">
				<input name="exportTemplate" value="#HtmlEditFormat( args.exportTemplate )#" type="hidden">
			</form>
		</cfif>
		<cfif allowSaveExport>
			<form action="#args.saveExportUrl#" method="post" class="hide object-listing-table-save-export-form">
				<input name="object" value="#args.objectName#" type="hidden">
				<input name="exportFilterString" value="#HtmlEditFormat( args.exportFilterString )#" type="hidden">
				<input name="exportTemplate" value="#HtmlEditFormat( args.exportTemplate )#" type="hidden">
			</form>
		</cfif>
		<cfif args.useMultiActions>
			<form id="multi-action-form-#instanceId#" data-prevent-multiple-submit="true" class="form-horizontal multi-action-form" method="post" action="#args.multiActionUrl#">
				<input type="hidden" name="multiAction" value="" />
		</cfif>

		<div class="object-listing-toolbar" id="#tableId#-toolbar">
			<script type="application/json" class="listing-toolbar-data">#SerializeJSON( toolbarConfig )#</script>
			<div class="object-listing-toolbar-row">
				<div class="object-listing-everything-bar">
					<div class="everything-bar-input-wrap input-icon">
						<i class="fa fa-search everything-bar-icon data-table-search-icon"></i>
						<input type="text"
							class="everything-bar-input data-table-search form-control"
							autocomplete="off"
							data-global-key="s"
							placeholder="#translateResource( uri='cms:datatables.everything.placeholder', data=[ args.objectTitlePlural ], defaultValue=translateResource( uri='cms:datamanager.search.placeholder', data=[ args.objectTitlePlural ] ) )#"
							<cfif !args.allowSearch && !args.allowFilter> disabled</cfif>
						/>
					</div>
					<div class="everything-bar-dropdown hide" role="listbox"></div>
				</div>
				<cfif args.allowFilter && allowUseFilter>
					<div class="filter-links-container">
						<cfif allowManageFilter && Len( Trim( manageFilterLink ) )>
							<a href="#manageFilterLink#"><i class="fa fa-fw fa-cogs"></i> #translateResource( "cms:datatables.manage.filters.link" )#</a>
						</cfif>
						<a href="##" class="advanced-filter-toggle"><i class="fa fa-fw fa-caret-right"></i> #translateResource( "cms:datatables.show.advanced.filters" )#</a>
					</div>
				</cfif>
			</div>
			<div class="everything-bar-chips"></div>
		</div>

		<cfif args.allowFilter>
			<cfif allowUseFilter>
				<div class="object-listing-table-filter object-listing-advanced-filter hide" id="#tableId#-filter" data-allow-manage-filter="#booleanFormat( allowManageFilter )#" data-allow-use-filter="#booleanFormat( allowUseFilter )#" data-manage-filters-link="#manageFilterLink#">
					<div class="object-listing-advanced-filter-header">
						<h3>#translateResource( uri="cms:datatables.show.advanced.filters" )#</h3>
						<button type="button" class="btn btn-link btn-sm advanced-filter-close">
							<i class="fa fa-times"></i>
						</button>
					</div>
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
							, showCount   = true
							, showPreview = false
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
					<cfif !isEmptyString( args.customExportUrl )>
						<a class="btn btn-info btn-sm" href="#args.customExportUrl#">
							<i class="fa fa-fw fa-download"></i>
							#translateResource(
								  uri          = "preside-objects.#args.objectName#:datatable.custom.export.btn"
								, defaultValue = translateResource( uri="cms:datatable.custom.export.btn" )
							)#
						</a>
					<cfelse>
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
					</cfif>
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
		    data-allow-column-picker="#allowColumnPicker#"
		    data-listing-key="#args.listingPreferenceKey#"
		    data-save-listing-columns-url="#args.saveListingColumnsUrl#"
		    data-hidden-grid-fields="#ArrayToList( args.hiddenGridFields )#"
		    data-is-multilingual="#args.isMultilingual#"
		    data-drafts-enabled="#args.draftsEnabled#"
		    data-clickable-rows="#args.clickableRows#"
		    data-no-actions="#args.noActions#"
		    data-allow-filter="#args.allowFilter#"
		    data-compact="#args.compact#"
		    data-no-record-message="#args.noRecordMessage#"
		    data-no-record-table-hide="#args.noRecordTableHide#"
		    data-no-record-table-hide-message="#EncodeForHTML( args.noRecordTableHideMessage )#"
		    data-footer-enabled="#args.footerEnabled#"
		    data-footer-wrap-with-row="#args.footerWrapWithRow#"
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
					<cfset listingColumns = [] />
					<cfif IsArray( toolbarConfig.columns ?: "" ) && ArrayLen( toolbarConfig.columns )>
						<cfloop array="#toolbarConfig.columns#" item="listingCol">
							<cfif allowColumnPicker || IsTrue( listingCol.visible ?: true )>
								<cfset ArrayAppend( listingColumns, listingCol ) />
							</cfif>
						</cfloop>
					</cfif>
					<cfif !ArrayLen( listingColumns )>
						<cfloop array="#args.gridFields#" index="fieldName">
							<cfset ArrayAppend( listingColumns, { field=fieldName, label="", locked=false, visible=true } ) />
						</cfloop>
					</cfif>
					<cfloop array="#listingColumns#" item="listingCol">
						<cfset fieldName = listingCol.field />
						<th class="listing-data-column<cfif IsTrue( listingCol.locked ?: false )> listing-locked-column<cfelse> listing-user-column</cfif><cfif !isEmpty( args.sortableFields ) and !arrayContains( args.sortableFields, fieldName )> no-sorting</cfif>"
							data-field="#ListLast( fieldName, '.' )#"
							data-visible="#booleanFormat( IsTrue( listingCol.visible ?: true ) )#"
							data-class="<cfif ArrayFindNoCase( args.centerAlignFields, fieldName )>dt-align-center<cfelseif ArrayFindNoCase( args.rightAlignFields, fieldName )>dt-align-right<cfelse></cfif>"
						>
							<cfif Len( Trim( listingCol.label ?: "" ) )>
								#listingCol.label#
							<cfelseif structKeyExists( args.gridHeaderLabels, fieldName ) >
								#args.gridHeaderLabels[ fieldName ]#
							<cfelse>
								#translatePropertyName( args.objectName, fieldName, "listing" )#
							</cfif>
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
				<cfif args.footerWrapWithRow>
					<tfoot>
						<tr>
							<th colspan="#colCount#"></th>
						</tr>
					</tfoot>
				<cfelse>
					<tfoot class="multi-column-footer">
						<tr></tr>
					</tfoot>
				</cfif>
			</cfif>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr<cfif args.useMultiActions> > td :checkbox<cfelse> a:nth-of-type(1)</cfif>">
			</tbody>
		</table>
		<cfif args.useMultiActions>
				<div class="form-actions multi-action-buttons" id="multi-action-buttons-#instanceId#">
					#renderViewlet( event="admin.datamanager._selectAllControl", args=args )#

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
