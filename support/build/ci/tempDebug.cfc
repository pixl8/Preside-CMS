component extends="tests.resources.HelperObjects.PresideTestCase" {
	function init(){
		return this;
	}

	function debugThisProblem(){
		return _getPresideObjectService().listObjects();
	}
}