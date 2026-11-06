module MyName
    module KCode
        # Хранит блоки-обработчики для разных типов кликов.
        # Создаётся при каждом KCodeContext#execute, заполняется
        # из кода компонента (self.click do ... end, self.click.shift do ... end).
        class ClickHandler
            # Только модификаторы. Базовый :left регистрируется
            # через метод call (self.click do ... end).
            TYPES = [
                :shift, :ctrl, :alt
            ].freeze

            INTERNAL = {
                shift: :left_shift,
                ctrl:  :left_ctrl,
                alt:   :left_alt
            }.freeze

            def initialize
                @handlers = {}
            end

            # self.click do ... end
            def call(&block)
                @handlers[:left] = block if block
            end

            # self.click.shift do ... end
            TYPES.each do |type|
                define_method(type) do |&block|
                    @handlers[INTERNAL[type]] = block if block
                end
            end

            def trigger(type)
                h = @handlers[type]
                return false unless h
                begin
                    h.call
                    true
                rescue => e
                    puts "[KCode/click #{type}] #{e.class}: #{e.message}"
                    false
                end
            end

            def has?(type)
                @handlers.key?(type)
            end

            def any?
                !@handlers.empty?
            end
        end
    end
end