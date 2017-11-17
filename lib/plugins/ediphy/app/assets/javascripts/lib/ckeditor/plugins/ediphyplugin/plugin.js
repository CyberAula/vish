(function () {
    CKEDITOR.plugins.add('ediphyplugin', {
        requires: 'dialog',
        lang: 'en,es', // %REMOVE_LINE_CORE%
        icons: 'ediphyplugin', // %REMOVE_LINE_CORE%
        hidpi: true, // %REMOVE_LINE_CORE%
        init: function (editor) {
            var lang = editor.lang.ediphyplugin;
            //allowed = 'plugin[*]{*}(*)';

            editor.addCommand('createediphyplugin', new CKEDITOR.dialogCommand('createediphyplugin'
                /*, {
                 allowedContent: allowed,
                 requiredContent: 'plugin[!plugin-data-id]',
                 contextSensitive: true,
                 refresh: function (editor, path) {
                 var context = editor.config.div_wrapTable ? path.root : path.blockLimit;
                 this.setState('div' in context.getDtd() ? CKEDITOR.TRISTATE_OFF : CKEDITOR.TRISTATE_DISABLED);
                 }
                 }*/
            ));

            editor.addCommand('editediphyplugin', new CKEDITOR.dialogCommand('editediphyplugin'));
            editor.addCommand('removeediphyplugin', {
                exec: function (editor) {
                    var selection = editor.getSelection();
                    var ranges = selection && selection.getRanges();
                    var range;
                    var bookmarks = selection.createBookmarks();
                    var walker;
                    var toRemove = [];

                    function findPlugin(node) {
                        var plugin = node.getAscendant('plugin', true);
                        if (plugin) {
                            toRemove.push(plugin.getAscendant('div'));
                        }
                    }

                    for (var i = 0; i < ranges.length; i++) {
                        range = ranges[i];
                        if (range.collapsed)
                            findPlugin(selection.getStartElement());
                        else {
                            walker = new CKEDITOR.dom.walker(range);
                            walker.evaluator = findPlugin;
                            walker.lastForward();
                        }
                    }

                    for (i = 0; i < toRemove.length; i++)
                        toRemove[i].remove();

                    selection.selectBookmarks(bookmarks);
                }
            });

            editor.ui.addButton && editor.ui.addButton('EdiphyPlugin', {
                label: lang.toolbar,
                command: 'createediphyplugin',
                toolbar: 'blocks,50'
            });

            if (editor.addMenuItems) {
                editor.addMenuItems({
                    editediphyplugin: {
                        label: lang.edit,
                        command: 'editediphyplugin',
                        group: 'div',
                        order: 1
                    },

                    removeediphyplugin: {
                        label: lang.remove,
                        command: 'removeediphyplugin',
                        group: 'div',
                        order: 5
                    }
                });

                if (editor.contextMenu) {
                    editor.contextMenu.addListener(function (element) {
                        if (!element || element.isReadOnly())
                            return null;

                        if (element.getAscendant('plugin', true)) {
                            return {
                                editediphyplugin: CKEDITOR.TRISTATE_OFF,
                                removeediphyplugin: CKEDITOR.TRISTATE_OFF
                            };
                        }

                        return null;
                    });
                }
            }

            CKEDITOR.dialog.add('createediphyplugin', this.path + 'dialogs/ediphyplugin.js');
            CKEDITOR.dialog.add('editediphyplugin', this.path + 'dialogs/ediphyplugin.js');
        }
    });
})();