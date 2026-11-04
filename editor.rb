require 'json'

module MyName
    module KCode
        @editing = { instance: nil }

        def self.show_editor
            if $kcode_dialog
                $kcode_dialog.show
                $kcode_dialog.bring_to_front
                refresh_editor
                return
            end

            $kcode_dialog = UI::HtmlDialog.new(
                dialog_title:    'KCode Editor',
                preferences_key: 'kcode_editor',
                width:           640,
                height:          460,
                resizable:       true,
                style:           UI::HtmlDialog::STYLE_DIALOG
            )
            $kcode_dialog.set_html(editor_html)
            $kcode_dialog.add_action_callback('kcode_save')    { |_, code| handle_save(code) }
            $kcode_dialog.add_action_callback('kcode_apply')   { |_, code| handle_apply(code) }
            $kcode_dialog.add_action_callback('kcode_refresh') { |_| refresh_editor }

            $kcode_dialog.add_action_callback('kcode_log')     { |_, msg| puts "[KCode/js] #{msg}" }
            $kcode_dialog.set_on_closed do
                $kcode_dialog = nil
            end
            $kcode_dialog.show



            refresh_editor
        end

        def self.refresh_editor
            return unless $kcode_dialog

            # Кнопка "Из компонента" ВСЕГДА смотрит на текущее выделение
            sel = Sketchup.active_model.selection.first
            inst = (sel.is_a?(Sketchup::ComponentInstance) && sel.valid?) ? sel : nil

            if inst
                @editing[:instance] = inst
                ctx  = KCodeContext.new(inst)
                info = "#{inst.definition.name}   (id #{inst.entityID})"
                $kcode_dialog.execute_script("window.setInfo(#{info.to_json}, true);")
                $kcode_dialog.execute_script("window.setCode(#{ctx.code.to_s.to_json});")
            else
                @editing[:instance] = nil
                $kcode_dialog.execute_script("window.setInfo('Компонент не выбран', false);")
                $kcode_dialog.execute_script("window.setCode('');")
            end
        end

        # Возвращает компонент для работы: сначала закэшированный (если жив),
        # потом — из текущего выделения.
        def self.current_target_instance
            cached = @editing[:instance]
            return cached if cached && cached.valid?

            sel = Sketchup.active_model.selection.first
            return sel if sel.is_a?(Sketchup::ComponentInstance) && sel.valid?

            nil
        end

        def self.handle_save(code)
            inst = current_target_instance
            unless inst
                puts '[KCode] Нет выбранного компонента — некуда сохранять.'
                return
            end
            KCodeContext.new(inst).save_code(code)
            puts "[KCode] Сохранено в #{inst.definition.name} (id #{inst.entityID})"
        end

        def self.handle_apply(code)
            inst = current_target_instance
            unless inst
                puts '[KCode] Нет выбранного компонента — некуда применять.'
                return
            end
            ctx = KCodeContext.new(inst)
            ctx.save_code(code)
            ctx.execute
            puts "[KCode] Применено к #{inst.definition.name} (id #{inst.entityID})"
        end

        def self.editor_html
            <<~HTML
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <style>
                        body { font-family: sans-serif; margin: 0; padding: 8px; background: #f0f0f0; }
                        #info {
                            padding: 6px 10px; background: #fff; border: 1px solid #ccc;
                            margin-bottom: 6px; font-size: 12px; border-radius: 2px;
                        }
                        #info.off { color: #a00; }
                        #code {
                            width: 100%; box-sizing: border-box; height: 300px;
                            font-family: 'Consolas', 'Menlo', 'Courier New', monospace;
                            font-size: 13px; line-height: 1.4;
                            padding: 8px; border: 1px solid #ccc; border-radius: 2px;
                            resize: none; tab-size: 4;
                        }
                        #buttons { margin-top: 8px; }
                        button {
                            padding: 6px 14px; margin-right: 6px;
                            cursor: pointer; font-size: 13px;
                        }
                        button:disabled { cursor: default; opacity: 0.5; }
                    </style>
                </head>
                <body>
                    <div id="info" class="off">Компонент не выбран</div>
                    <textarea id="code" spellcheck="false" placeholder="self.lenx  = self.parent_context.lenx / 2&#10;self.left  = 10.cm&#10;self.top   = 5.cm"></textarea>
                    <div id="buttons">
                        <button id="save">Сохранить</button>
                        <button id="apply">Применить</button>
                        <button id="refresh">Из компонента</button>
                    </div>
                    <script>
                        (function() {
                            var codeEl     = document.getElementById('code');
                            var infoEl     = document.getElementById('info');
                            var saveBtn    = document.getElementById('save');
                            var applyBtn   = document.getElementById('apply');
                            var refreshBtn = document.getElementById('refresh');

                            function log(msg) {
                                if (window.sketchup && sketchup.kcode_log) {
                                    sketchup.kcode_log(msg);
                                }
                            }

                            window.onerror = function(msg, url, line) {
                                log('JS ERROR: ' + msg + ' at ' + (url || '?') + ':' + (line || '?'));
                            };

                            window.setInfo = function(text, selected) {
                                infoEl.textContent = text;
                                if (selected) {
                                    infoEl.classList.remove('off');
                                } else {
                                    infoEl.classList.add('off');
                                }
                                saveBtn.disabled  = !selected;
                                applyBtn.disabled = !selected;
                            };

                            window.setCode = function(text) {
                                codeEl.value = text || '';
                            };

                            saveBtn.addEventListener('click', function() {
                                log('save clicked');
                                sketchup.kcode_save(codeEl.value);
                            });

                            applyBtn.addEventListener('click', function() {
                                log('apply clicked');
                                sketchup.kcode_apply(codeEl.value);
                            });

                            refreshBtn.addEventListener('click', function() {
                                log('refresh clicked');
                                sketchup.kcode_refresh();
                            });

                            // Tab = 4 пробела
                            codeEl.addEventListener('keydown', function(e) {
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
                    </script>
                </body>
                </html>
            HTML
        end
    end
end