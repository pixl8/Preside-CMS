<cfscript>
	param name="args.objectName"          type="string";
	param name="args.useMultiActions"     type="boolean" default=false;
	param name="args.multiActionViewlet"  type="string"  default="admin.datamanager._multiActions";
	param name="args.multiActionUrl"      type="string"  default="";
	param name="args.isMultilingual"      type="boolean" default=false;
	param name="args.draftsEnabled"       type="boolean" default=false;
	param name="args.gridFields"          type="array";
	param name="args.filterContextData"   type="struct"  default={};
	param name="args.allowSearch"         type="boolean" default=true;
	param name="args.allowFilter"         type="boolean" default=true;
	param name="args.allowDataExport"     type="boolean" default=false;
	param name="args.clickableRows"       type="boolean" default=true;
	param name="args.batchEditableFields" type="array"   default=[];
	param name="args.datasourceUrl"       type="string"  default=event.buildAdminLink( linkTo="ajaxProxy", queryString="id=#args.objectName#&action=dataManager.getObjectRecordsForAjaxDataTables&useMultiActions=#args.useMultiActions#&gridFields=#ArrayToList( args.gridFields )#&isMultilingual=#args.isMultilingual#&draftsEnabled=#args.draftsEnabled#" );
	param name="args.dataExportUrl"       type="string"  default=event.buildAdminLink( linkTo="dataManager.exportDataAction" );
	param name="args.dataExportConfigUrl" type="string"  default=event.buildAdminLink( linkTo="dataManager.dataExportConfigModal", queryString="id=#args.objectName#" );

	objectTitle          = translateResource( uri="preside-objects.#args.objectName#:title", defaultValue=args.objectName );
	deleteSelected       = translateResource( uri="cms:datamanager.deleteSelected.title" );
	deleteSelectedPrompt = translateResource( uri="cms:datamanager.deleteSelected.prompt", data=[ objectTitle ] );
	batchEditTitle       = translateResource( uri="cms:datamanager.batchEditSelected.title" );

	event.include( "/js/admin/specific/datamanager/object/");
	event.include( "/css/admin/specific/datamanager/object/");

	tableId = args.id ?: "object-listing-table-#LCase( args.objectName )#";

	args.allowFilter = args.allowFilter && isFeatureEnabled( "rulesengine" );

	if ( args.allowFilter ) {
		saveFilterFormEndpoint = event.buildAdminLink(
			  linkTo      = "rulesEngine.superQuickAddFilterForm"
			, querystring = "filter_object=#args.objectName#&multiple=false&expressions="
		);

		favourites = renderViewlet( event="admin.rulesEngine.dataGridFavourites", args={ objectName=args.objectName } );
	}

	allowDataExport = args.allowDataExport && isFeatureEnabled( "dataexport" );
</cfscript>
<cfoutput>
	<div class="table-responsive">
		<cfif allowDataExport>
			<form action="#args.dataExportUrl#" method="post" class="hide object-listing-table-export-form">
				<input name="object" value="#args.objectName#" type="hidden">
			</form>
		</cfif>
		<cfif args.useMultiActions>
			<form id="multi-action-form" class="form-horizontal" method="post" action="#args.multiActionUrl#">
				<input type="hidden" name="multiAction" value="" />
		</cfif>

		<cfif args.allowFilter>
			<div class="object-listing-table-filter hide" id="#tableId#-filter">
				<div class="row">
					<div class="col-md-12">
						<a class="pull-right back-to-basic-search" href="##">
							<i class="fa fa-fw fa-reply"></i>
							#translateResource( "cms:datatables.show.basic.search" )#
						</a>
						<h4 class="blue">#translateResource( "cms:rulesEngine.saved.filters" )#</h4>
						<p class="grey"><i class="fa fa-fw fa-info-circle"></i> <em>#translateResource( "cms:rulesEngine.saved.filters.help" )#</em></p>
						#renderFormControl(
							  name         = "filters"
							, id           = "filters"
							, type         = "filterPicker"
							, context      = "admin"
							, filterObject = args.objectName
							, multiple     = true
							, quickedit    = true
							, label        = ""
							, layout       = ""
							, compact      = true
							, showCount    = false
						)#
						<br><br>
						<a href="##" data-toggle="collapse" data-target="##quick-filter-form" class="quick-filter-toggler">
							<i class="fa fa-fw fa-caret-down"></i>#translateResource( "cms:rulesEngine.show.quick.filter" )#
						</a>
					</div>
				</div>

				<div id="quick-filter-form" class="in clearfix">
					#renderFormControl(
						  name        = "filter"
						, id          = "filter"
						, type        = "rulesEngineFilterBuilder"
						, context     = "admin"
						, contextData = args.filterContextData
						, object      = args.objectName
						, label       = ""
						, layout      = ""
						, compact     = true
						, showCount   = false
					)#

					<div class="form-actions">
						<div class="pull-right">
							<button class="btn btn-info btn-sm save-filter-btn" tabindex="#getNextTabIndex()#" disabled data-save-form-endpoint="#saveFilterFormEndpoint#">
								<i class="fa fa-fw fa-save"></i>
								#translateResource( "cms:rulesEngine.quick.filter.save.btn" )#
							</button>
						</div>
					</div>
				</div>
			</div>

			<div class="object-listing-table-favourites hide" id="#tableId#-favourites">
				#favourites#
			</div>
		</cfif>

		<cfif allowDataExport>
			<div class="object-listing-table-export hide">
				<div class="pull-left">
					<a class="btn btn-info btn-sm object-listing-data-export-button" href="#args.dataExportConfigUrl#">
						<i class="fa fa-fw fa-download"></i>
						#translateResource( "cms:datatable.export.btn" )#
					</a>
				</div>
			</div>
		</cfif>

		<table id="#tableId#" class="table table-hover object-listing-table"
			data-object-name="#args.objectName#"
		    data-datasource-url="#args.datasourceUrl#"
		    data-use-multi-actions="#args.useMultiActions#"
		    data-allow-search="#args.allowSearch#"
		    data-allow-data-export="#allowDataExport#"
		    data-is-multilingual="#args.isMultilingual#"
		    data-drafts-enabled="#args.draftsEnabled#"
		    data-clickable-rows="#args.clickableRows#"
		    data-allow-filter="#args.allowFilter#"
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
						<th data-field="#fieldName#">#translateResource( uri="preside-objects.#args.objectName#:field.#fieldName#.title", defaultValue=translateResource( "cms:preside-objects.default.field.#fieldName#.title" ) )#</th>
					</cfloop>
					<cfif args.draftsEnabled>
						<th>#translateResource( uri="cms:datamanager.column.draft.status" )#</th>
					</cfif>
					<cfif args.isMultilingual>
						<th>#translateResource( uri="cms:datamanager.translate.column.status" )#</th>
					</cfif>
					<th>&nbsp;</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr<cfif args.useMultiActions> > td :checkbox<cfelse> a:nth-of-type(1)</cfif>">
			</tbody>
		</table>
		<cfif args.useMultiActions>
				<div class="form-actions" id="multi-action-buttons">
					#renderViewlet( event=args.multiActionViewlet, args=args )#
				</div>
			</form>
		</cfif>
	</div>
</cfoutput>