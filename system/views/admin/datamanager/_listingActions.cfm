<cfparam name="args.viewRecordLink"    type="string" />
<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.viewHistoryLink"   type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />
<cfparam name="args.objectName"        type="string" />

<cfoutput>
	<div class="action-buttons btn-group">
		<i class="fa fa-cog dropdown-toggle" data-toggle="dropdown"></i>

		<ul class="dropdown-menu pull-right text-left">
			<cfif hasPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ args.objectName ] )>
				<li>
					<a href="#args.editRecordLink#" data-context-key="e">
						<i class="fa fa-pencil"></i>
						#translateResource( uri="cms:datatable.contextmenu.edit" )#
					</a>
				</li>
			</cfif>

			<cfif hasPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ args.objectName ] )>
				<li>
					<a class="confirmation-prompt" data-context-key="d" href="#args.deleteRecordLink#" title="#htmleditformat(args.deleteRecordTitle)#">
						<i class="fa fa-trash-o"></i>
						#translateResource( uri="cms:datatable.contextmenu.delete" )#
					</a>
				</li>
			</cfif>
			<cfif hasPermission( permissionKey="datamanager.viewversions", context="datamanager", contextKeys=[ args.objectName ] )>
				<li>
					<a data-context-key="h" href="#args.viewHistoryLink#">
						<i class="fa fa-history"></i>
						#translateResource( uri="cms:datatable.contextmenu.history" )#
					</a>
				</li>
			</cfif>
		</ul>
	</div>
</cfoutput>