module MyName
    module KCode
        class InteractTool
            CTRL_MASK  = 8
            SHIFT_MASK = 4
            ALT_MASK   = 32

            def activate
                @hover_component = nil
                @interact_cursor_id = UI.create_cursor(
                    File.join(__dir__, 'ui', 'icon_interact_cursor.png'), 10, 3
                )
                Sketchup.status_text = 'KCode Interact: кликайте по компонентам (Esc — выход)'
            end

            def deactivate(view)
                Sketchup.status_text = ''
                view.invalidate
            end

            def onSetCursor
                if @hover_component && @hover_component.valid? && @interact_cursor_id
                    UI.set_cursor(@interact_cursor_id)
                    true
                else
                    false
                end
            end

            def onLButtonDown(flags, x, y, view)
                handle_click(flags, x, y, view)
            end

            def onMouseMove(_flags, x, y, view)
                @hover_component = pick_component(x, y, view)
                if @hover_component && has_clicks?(@hover_component)
                    Sketchup.status_text = "KCode Interact: #{@hover_component.definition.name} (Esc — выход)"
                else
                    Sketchup.status_text = 'KCode Interact: кликайте по компонентам (Esc — выход)'
                end
            end

            def onCancel(_reason, view)
                Sketchup.active_model.select_tool(nil)
            end

            private

            def pick_component(x, y, view)
                ph = view.pick_helper
                ph.do_pick(x, y)
                inst = ph.best_picked
                inst.is_a?(Sketchup::ComponentInstance) ? inst : nil
            end

            def has_clicks?(inst)
                return false unless inst.valid?
                KCodeContext.new(inst).code_uses_clicks?
            end

            def handle_click(flags, x, y, view)
                inst = pick_component(x, y, view)
                return false unless inst
                return false unless inst.valid?

                ctx = KCodeContext.new(inst)
                return false unless ctx.code_uses_clicks?
                return false unless ctx.frozen?

                ctx.execute

                type = resolve_type(flags)
                if ctx.click.has?(type)
                    ctx.click.trigger(type)
                    view.invalidate
                    return true
                end
                false
            end

            def resolve_type(flags)
                if (flags & SHIFT_MASK) != 0
                    :left_shift
                elsif (flags & CTRL_MASK) != 0
                    :left_ctrl
                elsif (flags & ALT_MASK) != 0
                    :left_alt
                else
                    :left
                end
            end
        end

        def self.start_interact
            Sketchup.active_model.select_tool(InteractTool.new)
        end
    end
end