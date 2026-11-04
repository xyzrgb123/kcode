module MyName
    module KCode
        # Одна ось: размер и позиция.
        # Вся логика расчёта живёт в KCodeContext,
        # Axis — только фасад.
        class Axis
            def initialize(context, axis)
                raise ArgumentError, "unknown axis: #{axis}" unless [:x, :y, :z].include?(axis)
                @context = context
                @axis    = axis
            end

            def len
                @context.local_scale(@axis) *
                    @context.bounds_dim(@axis) *
                    @context.parent_scale_product(@axis)
            end

            def len=(value)
                base = @context.bounds_dim(@axis)
                return if base.nil? || base <= 0
                current = @context.local_scale(@axis)
                return if current.nil? || current == 0

                p_scale      = @context.parent_scale_product(@axis)
                target_local = value.to_f / p_scale
                target_scale = target_local / base
                @context.apply_scale(@axis, target_scale / current)
            end

            def pos
                @context.position(@axis)
            end

            def pos=(value)
                @context.set_position(@axis, value)
            end

            def scale
                @context.local_scale(@axis)
            end
        end
    end
end