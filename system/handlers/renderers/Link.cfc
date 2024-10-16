/**
 * @feature cms
 */
component {

	property name="linkDao"      inject="presidecms:object:link";
	property name="pageDao"      inject="presidecms:object:page";
	property name="linksService" inject="linksService";


// VIEWLETS
	private string function default( event, rc, prc, args={} ) {
		var link = linkDao.selectData( id=args.id ?: "" );

		if ( !link.recordCount ) {
			return "<!-- link not found -->";
		}

		args.href  = linksService.getLinkUrl( link.id );
		args.title = args.title ?: Trim( link.title );
		args.referrer_policy = args.referrer_policy ?: Trim( link.referrer_policy );
		if ( link.type == "asset" ) {
			args.download = isTrue( link.download );
		}

		if ( !Len( Trim( args.body ?: "" ) ) ) {
			if ( Len( Trim( link.image ) ) ) {
				args.body = renderAsset( assetId = link.image );
			} else if ( Len( Trim( link.text ) ) ) {
				args.body = Trim( link.text );
			} else if ( link.type == "email" ) {
				args.emailAntiSpam = args.email_anti_spam ?: false;
				args.body = linksService.emailAntiSpam( link.email_address, args.emailAntiSpam );
			} else if ( link.type == "sitetreelink" ) {
				var page = pageDao.selectData( id=link.page, selectFields=[ "title" ] );
				args.body = page.title;
			} else if ( link.type == "url" ) {
				args.body = args.href;
			} else {
				args.body = args.title;
			}
		}

		args.target = args.target ?: link.target;
		args.nofollow = IsTrue( args.nofollow ?: link.nofollow ?: "" )

		return renderView( view=( args.view ?: "/renderers/link/default" ), args=args );
	}
}