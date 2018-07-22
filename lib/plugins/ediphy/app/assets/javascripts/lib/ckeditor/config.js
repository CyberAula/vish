

CKEDITOR.editorConfig = function (config) {
    config.skin = 'bootstrapck';
    config.linkJavaScriptLinksAllowed = true;
    config.linkShowAdvancedTab = false;
    config.dialog_noConfirmCancel = true;
    config.pasteFromWordRemoveFontStyles = false;
    config.pasteFromWordRemoveStyles = false;
    config.allowedContent = true;
    config.entities = false;
    config.basicEntities = false;
    config.entities_latin = false;
    config.entities_greek = false;
    config.toolbarGroups = [
        {name: 'document', groups: ['document', 'mode', 'doctools']},
        {name: 'clipboard', groups: ['clipboard', 'undo']},
        {name: 'editing', groups: ['find', 'selection', 'spellchecker', 'editing']},
        {name: 'forms', groups: ['forms']},
        {name: 'basicstyles', groups: ['basicstyles', 'cleanup', 'colorbutton']},
        {name: 'links', groups: ['links']},
        {name: 'insert', groups: ['insert']}, 
        {name: 'colors', groups: ['colors']},
        '/',
        {name: 'paragraph', groups: ['list', 'indent', 'blocks', 'align', 'bidi', 'paragraph']},
        {name: 'styles', groups: ['styles']},
        {name: 'tools', groups: ['tools']},
        {name: 'others', groups: ['others']},
        {name: 'about', groups: ['about']}
    ];
    /*Currently disabled: plugin stylescombo
    config.stylesSet = [
        {name: 'Negrita', element: 'strong', attributes: {'class': 'ck_strong'}},
        {name: 'Cursiva', element: 'em', attributes: {'class': 'ck_em'}},
        {name: 'Encabezado 1', element: 'h1', attributes: {'class': 'ck_h1'}},       
       
    ];
*/  config.autoGrow_onStartup = true;
    config.removeButtons =
        'Anchor,' +
        'Unlink,';
    
    /*Currently disabled: plugin mathjax
        Necesario configurarlo también en index.html +visor
     */  

    config.mathJaxClass = 'math-tex';
    config.mathJaxLib = 'http://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS_HTML';    
    
    config.plugins =
        'a11yhelp,' +
        'basicstyles,' +
        'blockquote,' +
        'clipboard,' +
        'codesnippet,' +
        'colorbutton,' +
        'contextmenu,' +
        'dialog,' +
        'dialogui,' +
        'dialogadvtab,' +
        'enterkey,' +
        'entities,' +
        'filebrowser,' +
        'floatingspace,' +
        'floatpanel,' +
        'font,' +
        'format,' +
        'htmlwriter,' +
        'image,' +
        'indent,' +
        'indentlist,' +
        'indentblock,' +
        'justify,' +
        // 'lineheight,' +
        'lineutils,' +
        'link,' +
        'list,' +
        'liststyle,' +
        'magicline,' +
        'mathjax,' +
        'menu,' +
        'pastefromword,' +
        'panel,' +
        'pastetext,' +
        'pbckcode,' +
        'removeformat,' +
        'showborders,' +
        /*'stylescombo,' +*/
        'tab,' +
        'table,' +
        'tabletools,' +
        'toolbar,' +
        'undo,' +
        'widget,' +
        'widgetselection';
    config.extraPlugins = "tab"
/*config.keystrokes = [
    [CKEDITOR.CTRL + 90, 'doNothing']
    ];*/
 };
 
