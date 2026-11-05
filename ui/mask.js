(function () {
    'use strict';

    var checkboxes = document.querySelectorAll('input[type="checkbox"]');
    var maskEl = document.getElementById('currentMask');

    function log(msg) {
        if (window.sketchup && sketchup.kcode_log) {
            sketchup.kcode_log(msg);
        }
    }

    window.setMaskState = function (mask) {
        checkboxes.forEach(function (cb) {
            var bits = parseInt(cb.getAttribute('data-bits'), 10);
            // галочка = маркеры видны = биты НЕ установлены
            cb.checked = (mask & bits) === 0;
        });
        maskEl.textContent = 'mask = ' + mask;
    };

    checkboxes.forEach(function (cb) {
        cb.addEventListener('change', function () {
            var bits = parseInt(cb.getAttribute('data-bits'), 10);
            // галочка поставлена (checked=true) = маркеры видны = биты снять
            // галочка снята (checked=false) = маркеры скрыты = биты поставить
            var hide = !cb.checked;
            log('bits=' + bits + ' hide=' + hide);
            sketchup.kcode_set_mask_bits(bits, hide);
        });
    });

    log('mask dialog loaded');
})();