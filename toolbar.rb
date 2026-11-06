module MyName
    module KCode
        def self.show_toolbar
            return if @toolbar

            @toolbar = UI::Toolbar.new('KCode')

            editor_cmd = UI::Command.new('KCode Editor') do
                show_editor
            end
            editor_cmd.tooltip = 'Редактор кода компонента'
            editor_cmd.status_bar_text = 'Открыть редактор кода для выделенного компонента'
            editor_cmd.small_icon = File.join(__dir__, 'ui', 'icon_small.png')
            editor_cmd.large_icon = File.join(__dir__, 'ui', 'icon_large.png')

            mask_cmd = UI::Command.new('KCode Scale Mask') do
                show_mask_dialog
            end
            mask_cmd.tooltip = 'Маркеры масштаба'
            mask_cmd.status_bar_text = 'Настройка видимости маркеров Scale Tool'
            mask_cmd.small_icon = File.join(__dir__, 'ui', 'icon_scale_marker_small.png')
            mask_cmd.large_icon = File.join(__dir__, 'ui', 'icon_scale_marker_large.png')

            interact_cmd = UI::Command.new('KCode Interact') do
                start_interact
            end
            interact_cmd.tooltip = 'Режим кликов KCode'
            interact_cmd.status_bar_text = 'Активировать перехват кликов по компонентам с кодом'
            interact_cmd.small_icon = File.join(__dir__, 'ui', 'icon_interact_small.png')
            interact_cmd.large_icon = File.join(__dir__, 'ui', 'icon_interact_large.png')

            @toolbar.add_item(editor_cmd)
            @toolbar.add_item(mask_cmd)
            @toolbar.add_item(interact_cmd)
            @toolbar.show
        end
    end
end