<cfparam name="args.body" default="" />

<cfoutput>
	<div class="page-content">
		#renderView( view="admin/general/pageTitle", args={
			  title    = ( prc.pageTitle    ?: "" )
			, subTitle = ( prc.pageSubTitle ?: "" )
			, icon     = ( prc.pageIcon     ?: "" )
		} )#

		<div class="row modal-dialog-body">
			<div class="col-sm-12">
				#args.body#
			</div>
		</div>
	</div>
</cfoutput>