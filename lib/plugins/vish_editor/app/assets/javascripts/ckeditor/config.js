/*
Copyright (c) 2003-2012, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
	// Define changes to default configuration here. For example:
	// config.uiColor = '#AADC6E';
	if((VISH)&&(VISH.I18n)&&(typeof VISH.I18n.getLanguage == "function")){
		config.language = VISH.I18n.getLanguage();
	}
};