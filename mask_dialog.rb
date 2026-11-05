module MyName
    module KCode
        def self.show_mask_dialog
            if $kcode_mask_dialog
                $kcode_mask_dialog.show
                $kcode_mask_dialog.bring_to_front
                refresh_mask_dialog
                return
            end

            $kcode_mask_dialog = UI::HtmlDialog.new(
                dialog_title:    'KCode: маркеры масштаба',
                preferences_key: 'kcode_mask_dialog',
                width:           260,
                height:          180,
                resizable:       false,
                style:           UI::HtmlDialog::STYLE_UTILITY
            )
            $kcode_mask_dialog.set_file(File.join(__dir__, 'ui', 'mask.html'))
            $kcode_mask_dialog.add_action_callback('kcode_set_mask_bits') { |_, bits, hide| set_global_mask_bits(bits.to_i, hide) }
            $kcode_mask_dialog.add_action_callback('kcode_log')           { |_, msg| puts "[KCode/js] #{msg}" }
            $kcode_mask_dialog.set_on_closed do
                $kcode_mask_dialog = nil
            end
            $kcode_mask_dialog.show
            UI.start_timer(0.3, false) { refresh_mask_dialog }
        end

        def self.refresh_mask_dialog
            return unless $kcode_mask_dialog
            $kcode_mask_dialog.execute_script("window.setMaskState(#{global_mask});")
        end

        def self.global_mask
            Sketchup.active_model.get_attribute(MODEL_DICT, 'global_scale_mask', 0).to_i
        end

        # hide=true  -> биты в маске (маркеры скрыты)
        # hide=false -> биты сняты (маркеры видны)
        def self.set_global_mask_bits(bits, hide)
            bits = bits.to_i
            hide = (hide == true || hide == 'true')
            current = global_mask

            new_mask = hide ? (current | bits) : (current & ~bits)

            model = Sketchup.active_model
            model.start_operation('KCode: Global Scale Mask', true)
            model.set_attribute(MODEL_DICT, 'global_scale_mask', new_mask)

            model.definitions.each do |definition|
                next unless definition.respond_to?(:behavior)
                current_def = definition.behavior.no_scale_mask? || 0
                definition.behavior.no_scale_mask =
                    hide ? (current_def | bits) : (current_def & ~bits)
            end

            model.commit_operation
            model.active_view.invalidate
            puts "[KCode] Глобальная маска: #{new_mask}"
            refresh_mask_dialog
        end
    end
end