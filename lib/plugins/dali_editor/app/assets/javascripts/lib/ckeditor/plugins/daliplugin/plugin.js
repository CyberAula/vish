(function () {
    CKEDITOR.plugins.add('daliplugin', {
        requires: 'dialog',
        lang: 'en,es', // %REMOVE_LINE_CORE%
        icons: 'daliplugin', // %REMOVE_LINE_CORE%
        hidpi: true, // %REMOVE_LINE_CORE%
        init: function (editor) {
            var lang = editor.lang.daliplugin;
            //allowed = 'plugin[*]{*}(*)';

            editor.addCommand('createdaliplugin', new CKEDITOR.dialogCommand('createdaliplugin'
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

            editor.addCommand('editdaliplugin', new CKEDITOR.dialogCommand('editdaliplugin'));
            editor.addCommand('removedaliplugin', {
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

            editor.ui.addButton && editor.ui.addButton('DaliPlugin', {
                label: lang.toolbar,
                command: 'createdaliplugin',
                toolbar: 'blocks,50'
            });

            if (editor.addMenuItems) {
                editor.addMenuItems({
                    editdaliplugin: {
                        label: lang.edit,
                        command: 'editdaliplugin',
                        group: 'div',
                        order: 1
                    },

                    removedaliplugin: {
                        label: lang.remove,
                        command: 'removedaliplugin',
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
                                editdaliplugin: CKEDITOR.TRISTATE_OFF,
                                removedaliplugin: CKEDITOR.TRISTATE_OFF
                            };
                        }

                        return null;
                    });
                }
            }

            CKEDITOR.dialog.add('createdaliplugin', this.path + 'dialogs/daliplugin.js');
            CKEDITOR.dialog.add('editdaliplugin', this.path + 'dialogs/daliplugin.js');
        }
    });
})();