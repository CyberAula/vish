(function () {
    function divDialog(editor, command) {
        return {
            title: editor.lang.ediphyplugin.title,
            minWidth: 400,
            minHeight: 165,
            contents: [
                {
                    id: 'tab-basic',
                    label: editor.lang.common.generalTab,
                    title: editor.lang.common.generalTab,
                    //key, default, resizable, initial-height, display-name
                    elements: [
                        {
                            type: 'hbox',
                            widths: ['50%', '50%'],
                            children: [
                                {
                                    id: 'plugin-data-key',
                                    type: 'text',
                                    style: 'width: 100%;',
                                    label: editor.lang.ediphyplugin.keyLabel,
                                    required: true,
                                    validate: CKEDITOR.dialog.validate.notEmpty(editor.lang.ediphyplugin.validateKey),
                                    setup: function (element) {
                                        this.setValue(element.getAttribute("plugin-data-key"));
                                    },
                                    commit: function(data){
                                        data.key = this.getValue();
                                    }
                                },
                                {
                                    id: 'plugin-data-display-name',
                                    type: 'text',
                                    style: 'width: 100%;',
                                    label: editor.lang.ediphyplugin.displayNameLabel,
                                    setup: function (element) {
                                        this.setValue(element.getAttribute("plugin-data-display-name"));
                                    },
                                    commit: function(data){
                                        data.displayName = this.getValue();
                                    }
                                }
                            ]
                        },
                        {
                            id: 'plugin-data-default',
                            type: 'select',
                            style: 'width: 100%;',
                            label: editor.lang.ediphyplugin.defaultLabel,
                            'default': '',
                            items: [],
                            setup: function (element) {
                                this.setValue(element.getAttribute("plugin-data-default"));
                            },
                            commit: function(data){
                                data.default = this.getValue();
                            }
                        }
                    ]
                }
            ],
            onLoad: function () {
                var defaultSelect = this.getContentElement('tab-basic', 'plugin-data-default');
                defaultSelect.add('', '');
                Ediphy.Config.pluginList.map(function (item) {
                    defaultSelect.add(Ediphy.Plugins.get(item) ? Ediphy.Plugins.get(item).getConfig().displayName : item, item);
                });
            },
            onShow: function () {
                if (command == 'editediphyplugin') {
                    var element = editor.getSelection().getStartElement();
                    this.element = element;

                    this.setupContent(element);
                }
            },
            onOk: function () {
                var data = {};
                this.commitContent(data);
                var plugin = editor.document.createElement('plugin');

                plugin.setAttribute('plugin-data-key', data.key);
                plugin.setAttribute('plugin-data-display-name', data.displayName);
                plugin.setAttribute('plugin-data-default', data.default);

                plugin.setStyle('height', '28px');
                plugin.setStyle('display', 'block');
                plugin.setStyle('border', '1px solid black');

                var div = editor.document.createElement('div');
                plugin.appendTo(div);

                editor.insertElement(div);
            }
        };
    }

    CKEDITOR.dialog.add('createediphyplugin', function (editor) {
        return divDialog(editor, 'createediphyplugin');
    });

    CKEDITOR.dialog.add('editediphyplugin', function (editor) {
        return divDialog(editor, 'editediphyplugin');
    });

})();