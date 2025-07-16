/**
 * @feature assetManager
 */
component {

    property name="assetManagerService" inject="assetManagerService";

    public string function svgHtml( event, rc, prc, args={} ) {
        try {
            args.assetId     = args.id ?: "";
            args.assetBinary = assetManagerService.getAssetBinary( id=args.assetId );
        } catch ( any e ) {
            // If the asset is not found, we need to set the args.assetBinary to an empty string to avoid errors in the view.
            args.assetBinary = "";
            logError( e );
        }

        return renderView( view="/renderers/asset/svg/svgHtml", args=args );
    }
}