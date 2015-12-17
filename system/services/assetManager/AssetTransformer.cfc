/**
 * Used by the asset management system in generating asset derivatives. Methods defined here are available
 * to derivative transformation definitions. See [[assetmanager]] for more detials.
 *
 * @autodoc
 * @singleton
 *
 */
component displayname="Asset transformer" {

// CONSTRUCTOR

	/**
	 * @imageManipulationService.inject ImageManipulationService
	 */
	public any function init( required any imageManipulationService ) {
		_setImageManipulationService( imageManipulationService );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Resizes an image. Proxies to the [[api-imagemanipulationservice]] [[imagemanipulationservice-resize]] method.
	 *
	 * @autodoc
	 *
	 */
	public binary function resize() {
		return _getImageManipulationService().resize( argumentCollection = arguments );
	}

	/**
	 * Shrinks an image to fit a bounding box. Proxies to the [[api-imagemanipulationservice]] [[imagemanipulationservice-shrinktofit]] method.
	 *
	 * @autodoc
	 *
	 */
	public binary function shrinkToFit() {
		return _getImageManipulationService().shrinkToFit( argumentCollection = arguments );
	}

	/**
	 * Generates a preview image of a PDF. Proxies to the [[api-imagemanipulationservice]] [[imagemanipulationservice-pdfpreview]] method.
	 *
	 * @autodoc
	 *
	 */
	public binary function pdfPreview() {
		return _getImageManipulationService().pdfPreview( argumentCollection = arguments );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getImageManipulationService() {
		return _imageManipulationService;
	}
	private void function _setImageManipulationService( required any imageManipulationService ) {
		_imageManipulationService = arguments.imageManipulationService;
	}
}