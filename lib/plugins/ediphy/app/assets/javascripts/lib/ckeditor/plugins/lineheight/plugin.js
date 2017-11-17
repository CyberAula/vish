(function() {
    function addCombo(editor, comboName, styleType, lang, entries, defaultLabel, styleDefinition, order) {
        let config = editor.config, style = new CKEDITOR.style(styleDefinition);
        let names = entries.split(';'), values = [];
        let styles = {};
        for (let i = 0; i < names.length; i++) {
            let parts = names[ i ];
            if (parts) {
                parts = parts.split('/');
                let vars = {}, name = names[ i ] = parts[ 0 ];
                vars[ styleType ] = values[ i ] = parts[ 1 ] || name;
                styles[ name ] = new CKEDITOR.style(styleDefinition, vars);
                styles[ name ]._.definition.name = name;
            } else
            {names.splice(i--, 1);}
        }
        editor.ui.addRichCombo(comboName, {
            label: editor.lang.lineheight.title,
            title: editor.lang.lineheight.title,
            toolbar: 'styles,' + order,
            allowedContent: style,
            requiredContent: style,
            panel: {
                css: [CKEDITOR.skin.getPath('editor')].concat(config.contentsCss),
                multiSelect: false,
                attributes: { 'aria-label': editor.lang.lineheight.title },
            },
            init: function() {
                this.startGroup(editor.lang.lineheight.title);
                for (let i = 0; i < names.length; i++) {
                    let name = names[ i ];
                    this.add(name, styles[ name ].buildPreview(), name);
                }
            },
            onClick: function(value) {
                editor.focus();
                editor.fire('saveSnapshot');
                let style = styles[ value ];
                editor[ this.getValue() == value ? 'removeStyle' : 'applyStyle' ](style);
                editor.fire('saveSnapshot');
            },
            onRender: function() {
                editor.on('selectionChange', function(ev) {
                    let currentValue = this.getValue();
                    let elementPath = ev.data.path, elements = elementPath.elements;
                    for (var i = 0, element; i < elements.length; i++) {
                        element = elements[ i ];
                        for (let value in styles) {
                            if (styles[ value ].checkElementMatch(element, true, editor)) {
                                if (value != currentValue)
                                {this.setValue(value);}
                                return;
                            }
                        }
                    }
                    this.setValue('', defaultLabel);
                }, this);
            },
            refresh: function() {
                if (!editor.activeFilter.check(style))
                {this.setState(CKEDITOR.TRISTATE_DISABLED);}
            },
        });
    }
    CKEDITOR.plugins.add('lineheight', {
        requires: 'richcombo',
        lang: 'ar,de,en,es,fr,ko,pt',
        init: function(editor) {
            let config = editor.config;
            addCombo(editor, 'lineheight', 'size', editor.lang.lineheight.title, config.line_height, editor.lang.lineheight.title, config.lineHeight_style, 40);
        },
    });
})();
CKEDITOR.config.line_height = '1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;41;42;43;44;45;46;47;48;49;50;51;52;53;54;55;56;57;58;59;60;61;62;63;64;65;66;67;68;69;70;71;72';
CKEDITOR.config.lineHeight_style = {
    element: 'span',
    styles: { 'line-height': '#(size)' },
    overrides: [{
        element: 'line-height', attributes: { 'size': null },
    }],
};
