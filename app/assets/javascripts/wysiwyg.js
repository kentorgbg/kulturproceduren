jQuery.noConflict();
(function($) {
    var ck_config = {
        toolbar: [
            ['Bold', 'Italic', 'Underline', 'Strike'],
            ['NumberedList', 'BulletedList', '-', 'Blockquote', '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock', '-', 'Table'],
            ['Link', 'Unlink'],
            ['Format'],
            ['Maximize']
        ],
        toolbarCanCollapse: false,
        coreStyles_bold: { element: 'span', attributes: { 'style': 'font-weight: bold' } },
        coreStyles_italic: { element: 'span', attributes: { 'style': 'font-style: italic' } },
        coreStyles_underline: { element: 'span', attributes: { 'style': 'text-decoration: underline' } },
        coreStyles_strike: { element: 'span', attributes: { 'style': 'text-decoration: line-through' } },
        language: 'sv',
        height: '22em',
        width: '100%',
        format_tags: 'p;h2;h3;h4',
        uiColor: '#f5f5f5',
        stylesSet: [],
        //contentsCss: appPath + 'assets/editors.css',
        forcePasteAsPlainText: true,
        keystrokes: [],
        entities: false,
        htmlEncodeOutput: false,
        forceSimpleAmpersand: true,
        plugins: 'dialogui,dialog,a11yhelp,dialogadvtab,basicstyles,bidi,blockquote,button,panelbutton,panel,floatpanel,templates,menu,contextmenu,div,resize,toolbar,enterkey,entities,popup,listblock,richcombo,font,forms,format,htmlwriter,iframe,wysiwygarea,indent,indentblock,indentlist,justify,menubutton,language,link,list,liststyle,maximize,pastetext,pastefromword,removeformat,showblocks,showborders,sourcearea,stylescombo,tab,table,tabletools',
    };
    $('.ckeditor').ckeditor($.noop, ck_config);
})(jQuery);
