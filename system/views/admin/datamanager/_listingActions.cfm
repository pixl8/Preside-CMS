<cfparam name="args.viewRecordLink"    type="string" />
<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.viewHistoryLink"   type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />
<cfparam name="args.objectName"        type="string" />
<cfparam name="args.canView"           type="boolean" />
<cfparam name="args.canEdit"           type="boolean" />
<cfparam name="args.canDelete"         type="boolean" />
<cfparam name="args.canViewHistory"    type="boolean" />

<cfoutput>
	<div class="action-buttons btn-group">
		<cfif args.canView>
			<a href="#args.viewRecordLink#" data-context-key="v">
				<i class="fa fa-fw fa-eye"></i>
			</a>
		</cfif>

		<cfif args.canEdit>
			<a href="#args.editRecordLink#" data-context-key="e">
				<i class="fa fa-fw fa-pencil"></i>
			</a>
		</cfif>

		<cfif args.canDelete>
			<a class="confirmation-prompt" data-context-key="d" href="#args.deleteRecordLink#" title="#htmleditformat(args.deleteRecordTitle)#">
				<i class="fa fa-fw fa-trash-o"></i>
			</a>
		</cfif>

		<cfsavecontent variable="extraMenuItems">
			<cfif args.canViewHistory>
				<li>
					<a data-context-key="h" href="#args.viewHistoryLink#">
						<i class="fa fa-fw fa-history"></i>
						#translateResource( uri="cms:datatable.contextmenu.history" )#
					</a>
				</li>
			</cfif>
		</cfsavecontent>

		<cfif Len( Trim( extraMenuItems ) )>
			<a class="dropdown-toggle" data-toggle="dropdown"><i class="fa fa-fw fa-cog"></i></a>

			<ul class="dropdown-menu pull-right text-left">
				#extraMenuItems#
			</ul>
		</cfif>
	</div>
</cfoutput>