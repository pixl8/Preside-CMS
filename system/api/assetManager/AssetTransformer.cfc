component output=false singleton=true {

// CONSTRUCTOR

	/**
	 * @imageManipulationService.inject ImageManipulationService
	 */
	public any function init( required any imageManipulationService ) output=false {
		_setImageManipulationService( imageManipulationService );

		return this;
	}

// PUBLIC API METHODS
	public binary function resize() output=false {
		return _getImageManipulationService().resize( argumentCollection = arguments );
	}

	public binary function shrinkToFit() output=false {
		return _getImageManipulationService().shrinkToFit( argumentCollection = arguments );
	}

	public binary function pdfPreview() output=false {
		return _getImageManipulationService().pdfPreview( argumentCollection = arguments );
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getImageManipulationService() output=false {
		return _imageManipulationService;
	}
	private void function _setImageManipulationService( required any imageManipulationService ) output=false {
		_imageManipulationService = arguments.imageManipulationService;
	}
}