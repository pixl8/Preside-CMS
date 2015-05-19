<cfparam name="args.linkTitle" type="string" />
<cfoutput>
	<a href="##" class="form-control form-control-no-border one-to-many-manager" data-manager-url="#event.buildAdminLink( linkTo='datamanager.manageOneToManyRecords' )#" data-modal-title="Hello!">#args.linkTitle#</a>
</cfoutput>