module MyName
    module KCode
        # Стороны компонента (left/right/front/back/bottom/top).
        # Геттер возвращает зазор от соответствующего края родителя,
        # сеттер ставит зазор. Вся математика — в KCodeContext
        # (side_gap и set_side_gap).
        class Side
            SIDES = {
                left:   [:x, :min], right:  [:x, :max],
                front:  [:y, :min], back:   [:y, :max],
                bottom: [:z, :min], top:    [:z, :max]
            }.freeze

            def initialize(context, side)
                raise ArgumentError, "unknown side: #{side}" unless SIDES.key?(side)
                @context = context
                @side    = side
            end

            def gap
                @context.side_gap(@side)
            end

            def gap=(value)
                @context.set_side_gap(@side, value)
            end
        end
    end
end