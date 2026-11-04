(function () {
    'use strict';

    var codeEl        = document.getElementById('code');
    var tabComponent  = document.getElementById('tabComponent');
    var tabModel      = document.getElementById('tabModel');
    var copyBtn       = document.getElementById('copyBtn');
    var pasteBtn      = document.getElementById('pasteBtn');
    var applyBtn      = document.getElementById('applyBtn');
    var freezeBtn     = document.getElementById('freezeBtn');
    var fontMinusBtn  = document.getElementById('fontMinusBtn');
    var fontPlusBtn   = document.getElementById('fontPlusBtn');

    var changeTimer = null;
    var suppressChangeNotify = false;
    var currentMode = 'component';

    var FONT_MIN = 9;
    var FONT_MAX = 28;
    var FONT_DEFAULT = 13;
    var fontSize = FONT_DEFAULT;

    function log(msg) {
        if (window.sketchup && sketchup.kcode_log) {
            sketchup.kcode_log(msg);
        }
    }

    window.onerror = function (msg, url, line) {
        log('JS ERROR: ' + msg + ' at ' + (url || '?') + ':' + (line || '?'));
    };

    function applyFontSize(px) {
        fontSize = Math.max(FONT_MIN, Math.min(FONT_MAX, px));
        codeEl.style.fontSize = fontSize + 'px';
        var tabSize = Math.max(9, fontSize - 1);
        tabComponent.style.fontSize = tabSize + 'px';
        tabModel.style.fontSize = tabSize + 'px';
        if (window.sketchup && sketchup.kcode_save_font_size) {
            sketchup.kcode_save_font_size(fontSize);
        }
    }

    function setActiveTab(mode) {
        currentMode = mode;
        if (mode === 'model') {
            tabComponent.classList.remove('active');
            tabModel.classList.add('active');
            freezeBtn.disabled = true;
            freezeBtn.className = '';
            freezeBtn.title = 'Для модели недоступно';
        } else {
            tabModel.classList.remove('active');
            tabComponent.classList.add('active');
        }
    }

    window.setComponentName = function (text, selected) {
        tabComponent.textContent = text;
        if (selected) {
            tabComponent.classList.remove('off');
        } else {
            tabComponent.classList.add('off');
        }
        if (currentMode === 'component') {
            applyBtn.disabled = !selected;
            copyBtn.disabled  = !selected;
        }
    };

    window.setModelName = function (text) {
        tabModel.textContent = text;
    };









    window.setMode = function (mode) {
        setActiveTab(mode);
        if (mode === 'model') {
            applyBtn.disabled = false;
            copyBtn.disabled  = false;
        } else {
            var hasComp = !tabComponent.classList.contains('off');
            applyBtn.disabled = !hasComp;
            copyBtn.disabled  = !hasComp;
        }
    };








    window.setCode = function (text) {
        suppressChangeNotify = true;
        codeEl.value = text || '';
        setTimeout(function () { suppressChangeNotify = false; }, 0);
    };

    window.setFrozen = function (frozen) {
        if (frozen === null || frozen === undefined) {
            freezeBtn.disabled = true;
            freezeBtn.className = '';
            freezeBtn.title = 'Заморозить / Разморозить';
            return;
        }
        freezeBtn.disabled = false;
        if (frozen) {
            freezeBtn.className = 'frozen';
            freezeBtn.title = 'Разморозить';
        } else {
            freezeBtn.className = 'unfrozen';
            freezeBtn.title = 'Заморозить';
        }
    };

    window.setFontSize = function (px) {
        applyFontSize(px);
    };

    tabComponent.addEventListener('click', function () {
        if (currentMode === 'component') return;
        log('tab component clicked');
        sketchup.kcode_switch_mode('component');
    });

    tabModel.addEventListener('click', function () {
        if (currentMode === 'model') return;
        log('tab model clicked');
        sketchup.kcode_switch_mode('model');
    });

    codeEl.addEventListener('input', function () {
        if (suppressChangeNotify) return;
        if (changeTimer) clearTimeout(changeTimer);
        changeTimer = setTimeout(function () {
            changeTimer = null;
            if (window.sketchup && sketchup.kcode_notify_change) {
                sketchup.kcode_notify_change(codeEl.value);
            }
        }, 200);
    });

    copyBtn.addEventListener('click', function () {
        log('copy clicked');
        sketchup.kcode_copy(codeEl.value);
    });

    pasteBtn.addEventListener('click', function () {
        log('paste clicked');
        sketchup.kcode_paste();
    });

    applyBtn.addEventListener('click', function () {
        log('apply clicked');
        sketchup.kcode_apply(codeEl.value);
    });

    freezeBtn.addEventListener('click', function () {
        log('freeze toggle clicked');
        sketchup.kcode_toggle_freeze();
    });

    fontMinusBtn.addEventListener('click', function () {
        applyFontSize(fontSize - 1);
    });

    fontPlusBtn.addEventListener('click', function () {
        applyFontSize(fontSize + 1);
    });

    document.addEventListener('keydown', function (e) {
        if (!e.ctrlKey) return;
        if (e.key === '=' || e.key === '+') {
            e.preventDefault();
            applyFontSize(fontSize + 1);
        } else if (e.key === '-') {
            e.preventDefault();
            applyFontSize(fontSize - 1);
        } else if (e.key === 's' || e.key === 'S') {
            e.preventDefault();
            if (!applyBtn.disabled) sketchup.kcode_apply(codeEl.value);
        }
    });

    codeEl.addEventListener('keydown', function (e) {
        if (e.key === 'Tab') {
            e.preventDefault();
            var start = this.selectionStart;
            var end   = this.selectionEnd;
            this.value = this.value.substring(0, start) + '    ' + this.value.substring(end);
            this.selectionStart = this.selectionEnd = start + 4;
        }
    });

    log('editor loaded');
})();