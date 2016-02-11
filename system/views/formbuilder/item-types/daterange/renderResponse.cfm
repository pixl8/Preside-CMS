<cfparam name="args.dateFrom" type="string" />
<cfparam name="args.dateTo"   type="string" />

<cfoutput>
	<strong>#translateResource( "formbuilder.item-types.daterange:from.label")#</strong>: #args.dateFrom#<br>
	<strong>#translateResource( "formbuilder.item-types.daterange:to.label")#</strong>: #args.dateTo#
</cfoutput>