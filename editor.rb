require 'json'

module MyName
    module KCode
        @editing = { instance: nil, pending_code: nil, clipboard: nil, mode: :component }

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
            $kcode_dialog.set_file(File.join(__dir__, 'ui', 'editor.html'))
            $kcode_dialog.add_action_callback('kcode_apply')          { |_, code| handle_apply(code) }
            $kcode_dialog.add_action_callback('kcode_notify_change')  { |_, code| handle_code_changed(code) }
            $kcode_dialog.add_action_callback('kcode_toggle_freeze')  { |_| handle_toggle_freeze }
            $kcode_dialog.add_action_callback('kcode_copy')           { |_, code| handle_copy(code) }
            $kcode_dialog.add_action_callback('kcode_paste')          { |_| handle_paste }
            $kcode_dialog.add_action_callback('kcode_save_font_size') { |_, px| handle_save_font_size(px) }
            $kcode_dialog.add_action_callback('kcode_switch_mode')    { |_, mode| handle_switch_mode(mode) }
            $kcode_dialog.add_action_callback('kcode_log')            { |_, msg| puts "[KCode/js] #{msg}" }
            $kcode_dialog.set_on_closed do
                save_pending_code
                $kcode_dialog = nil
            end
            $kcode_dialog.show
            UI.start_timer(0.3, false) { refresh_editor }
        end

        def self.refresh_editor
            return unless $kcode_dialog

            font_size = Sketchup.read_default('kcode', 'font_size', 13).to_i
            $kcode_dialog.execute_script("window.setFontSize(#{font_size});")

            update_tab_names

            if @editing[:mode] == :model
                show_model_code
            else
                show_component_code
            end

            $kcode_dialog.execute_script("window.setMode(#{@editing[:mode].to_s.to_json});")
        end

        def self.update_tab_names
            inst = single_selected_component
            if inst
                $kcode_dialog.execute_script("window.setComponentName(#{inst.definition.name.to_json}, true);")
            else
                $kcode_dialog.execute_script("window.setComponentName('не выбран', false);")
            end
        end

        def self.show_component_code
            inst = single_selected_component
            if inst
                @editing[:instance] = inst
                @editing[:pending_code] = nil
                ctx = KCodeContext.new(inst)
                $kcode_dialog.execute_script("window.setCode(#{ctx.code.to_s.to_json});")
                $kcode_dialog.execute_script("window.setFrozen(#{ctx.frozen?});")
            else
                @editing[:instance] = nil
                @editing[:pending_code] = nil
                $kcode_dialog.execute_script("window.setCode('');")
                $kcode_dialog.execute_script("window.setFrozen(null);")
            end
        end

        def self.show_model_code
            ctx = ModelContext.new(Sketchup.active_model)
            @editing[:pending_code] = nil
            $kcode_dialog.execute_script("window.setCode(#{ctx.code.to_s.to_json});")
        end

        def self.single_selected_component
            sel = Sketchup.active_model.selection
            return nil unless sel.size == 1
            inst = sel[0]
            (inst.is_a?(Sketchup::ComponentInstance) && inst.valid?) ? inst : nil
        end

        def self.handle_code_changed(code)
            @editing[:pending_code] = code
        end

        def self.save_pending_code
            pending = @editing[:pending_code]
            return if pending.nil?
            @editing[:pending_code] = nil

            if @editing[:mode] == :model
                ModelContext.new(Sketchup.active_model).save_code(pending)
                puts '[KCode] Автосохранение: модель'
            else
                inst = @editing[:instance]
                return unless inst && inst.valid?
                KCodeContext.new(inst).save_code(pending)
                puts "[KCode] Автосохранение: #{inst.definition.name}"
            end
        end

        def self.handle_selection_changed
            return unless $kcode_dialog

            if @editing[:mode] == :model
                # В режиме модели не трогаем код, но обновляем имя вкладки компонента
                inst = single_selected_component
                if inst
                    $kcode_dialog.execute_script("window.setComponentName(#{inst.definition.name.to_json}, true);")
                else
                    $kcode_dialog.execute_script("window.setComponentName('не выбран', false);")
                end
                return
            end

            save_pending_code
            refresh_editor
        end

        def self.handle_switch_mode(mode)
            return unless $kcode_dialog

            new_mode = mode.to_s == 'model' ? :model : :component
            return if new_mode == @editing[:mode]

            save_pending_code
            @editing[:mode] = new_mode
            refresh_editor
        end

        def self.handle_apply(code)
            if @editing[:mode] == :model
                ctx = ModelContext.new(Sketchup.active_model)
                ctx.save_code(code)
                @editing[:pending_code] = nil
                ctx.execute
                puts '[KCode] Применено к модели'
                return
            end

            inst = @editing[:instance]
            unless inst && inst.valid?
                puts '[KCode] Нет выбранного компонента — некуда применять.'
                return
            end

            ctx = KCodeContext.new(inst)
            ctx.save_code(code)
            @editing[:pending_code] = nil
            ctx.force_apply_rotations!
            ctx.execute
            puts "[KCode] Применено к #{inst.definition.name} (id #{inst.entityID})"

        end

        def self.handle_toggle_freeze
            return if @editing[:mode] == :model

            inst = @editing[:instance]
            unless inst && inst.valid?
                puts '[KCode] Нет выбранного компонента — нечего замораживать.'
                return
            end

            ctx = KCodeContext.new(inst)
            if ctx.frozen?
                ctx.unfreeze!
                puts "[KCode] Разморожен: #{inst.definition.name}"
            else
                ctx.freeze!
                ctx.force_apply_rotations!
                puts "[KCode] Заморожен: #{inst.definition.name}"
            end

            $kcode_dialog.execute_script("window.setFrozen(#{ctx.frozen?});") if $kcode_dialog
        end

        def self.handle_copy(code)
            @editing[:clipboard] = code
            begin
                UI.set_clipboard(code)
            rescue StandardError
            end
            puts "[KCode] Скопировано (#{code.length} символов)"
        end

        def self.handle_paste
            text = @editing[:clipboard]
            if text.nil? || text.empty?
                puts '[KCode] Буфер пуст — сначала скопируйте код.'
                return
            end
            $kcode_dialog.execute_script("window.setCode(#{text.to_json});") if $kcode_dialog
            @editing[:pending_code] = text
            puts "[KCode] Вставлено (#{text.length} символов)"
        end

        def self.handle_save_font_size(px)
            size = px.to_i
            return if size < 9 || size > 28
            Sketchup.write_default('kcode', 'font_size', size)
        end
    end
end