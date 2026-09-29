/*! ColumnControl Bootstrap 3 styling 2.0.1 for DataTables
 * Copyright (c) SpryMedia Ltd - datatables.net/license
 */

(function(factory){
	if (typeof define === 'function' && define.amd) {
		// AMD
		define(['datatables.net-bs', 'datatables.net-columncontrol'], function (dt) {
			return factory(window, document, dt);
		});
	}
	else if (typeof exports === 'object') {
		// CommonJS
		var cjsRequires = function (root) {
			if (! root.DataTable) {
				require('datatables.net-bs')(root);
			}

			if (! window.DataTable.ColumnControl) {
				require('datatables.net-columncontrol')(root);
			}
		};

		if (typeof window === 'undefined') {
			module.exports = function (root) {
				if (! root) {
					// CommonJS environments without a window global must pass a
					// root. This will give an error otherwise
					root = window;
				}

				cjsRequires(root);
				return factory(root, root.document, root.DataTable);
			};
		}
		else {
			cjsRequires(window);
			module.exports = factory(window, window.document, window.DataTable);
		}
	}
	else {
		// Browser
		factory(window, document, window.DataTable);
	}
}(function(window, document, DataTable) {
'use strict';



DataTable.ColumnControl.content.dropdown.classes.container = [
	'dtcc-dropdown',
	'dropdown-menu',
	'show'
];

DataTable.ColumnControl.CheckList.classes.input = [
	'dtcc-list-search',
	'form-control',
	'form-control-sm'
];
DataTable.ColumnControl.SearchInput.classes.input = ['form-control', 'form-control-sm'];
DataTable.ColumnControl.SearchInput.classes.select = ['form-control', 'form-control-sm'];


return DataTable;
}));
