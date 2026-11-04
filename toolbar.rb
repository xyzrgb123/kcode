module MyName
    module KCode
        def self.show_toolbar
            return if @toolbar

            @toolbar = UI::Toolbar.new('KCode')

            cmd = UI::Command.new('KCode Editor') do
                show_editor
            end
            cmd.tooltip     = 'Редактор кода компонента'
            cmd.status_bar_text = 'Открыть редактор кода для выделенного компонента'
            cmd.small_icon  = File.join(__dir__, 'ui', 'icon_small.png')
            cmd.large_icon  = File.join(__dir__, 'ui', 'icon_large.png')

            @toolbar.add_item(cmd)
            @toolbar.show
        end
    end
end