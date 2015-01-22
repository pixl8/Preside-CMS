<cfparam name="args.title" type="string" />
<cfparam name="args.id"    type="string" />

<cfoutput>
	<tr class="clickable asset" data-id="#args.id#">
		<td>#renderAsset( assetId=args.id, context="icon" )#</td>
		<td>#args.title# <i class="selected-icon fa fa-check-circle green pull-right"></i></td>
	</tr>
</cfoutput>