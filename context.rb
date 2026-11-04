# KCodeContext (собирает всё вместе)

module MyName
    module KCode
        class KCodeContext
            def initialize(instance)
                @instance   = instance
                @definition = instance.definition
                @axes       = {}
                @sides      = {}
            end

            def valid?
                @instance.valid? && @definition.valid?
            end

            def save_code(code_string)
                @definition.set_attribute(DICT_NAME, CODE_KEY, code_string)
            end

            def code
                @definition.get_attribute(DICT_NAME, CODE_KEY, '')
            end

            def execute
                unless valid?
                    raise '[KCode] Экземпляр компонента был удалён. ' \
                          'Создайте новый контекст из живого объекта.'
                end

                code_to_run = code
                return if code_to_run.nil? || code_to_run.empty?

                mdl = @instance.model
                mdl.start_operation('KCode Execute', true)
                begin
                    instance_eval(code_to_run)
                rescue => e
                    puts "[KCode] #{e.class}: #{e.message}"
                    puts e.backtrace.first(5).join("\n")
                ensure
                    mdl.commit_operation
                end
            end

            # --- Оси ---
            def x_axis; @axes[:x] ||= Axis.new(self, :x); end
            def y_axis; @axes[:y] ||= Axis.new(self, :y); end
            def z_axis; @axes[:z] ||= Axis.new(self, :z); end

            def lenx;      x_axis.len;      end
            def lenx=(v);  self.x_axis.len = v;  end
            def leny;      y_axis.len;      end
            def leny=(v);  self.y_axis.len = v;  end
            def lenz;      z_axis.len;      end
            def lenz=(v);  self.z_axis.len = v;  end

            def x;         x_axis.pos;      end
            def x=(v);     self.x_axis.pos = v;  end
            def y;         y_axis.pos;      end
            def y=(v);     self.y_axis.pos = v;  end
            def z;         z_axis.pos;      end
            def z=(v);     self.z_axis.pos = v;  end

            # --- Стороны ---
            def left_side;   @sides[:left]   ||= Side.new(self, :left);   end
            def right_side;  @sides[:right]  ||= Side.new(self, :right);  end
            def front_side;  @sides[:front]  ||= Side.new(self, :front);  end
            def back_side;   @sides[:back]   ||= Side.new(self, :back);   end
            def bottom_side; @sides[:bottom] ||= Side.new(self, :bottom); end
            def top_side;    @sides[:top]    ||= Side.new(self, :top);    end

            def left;       left_side.gap;       end
            def left=(v);   self.left_side.gap = v;   end
            def right;      right_side.gap;      end
            def right=(v);  self.right_side.gap = v;  end
            def front;      front_side.gap;      end
            def front=(v);  self.front_side.gap = v;  end
            def back;       back_side.gap;       end
            def back=(v);   self.back_side.gap = v;   end
            def bottom;     bottom_side.gap;     end
            def bottom=(v); self.bottom_side.gap = v; end
            def top;        top_side.gap;        end
            def top=(v);    self.top_side.gap = v;    end

            # --- Модель ---
            def model
                @instance.model
            end

            def mvar(key, default = nil)
                model.get_attribute(MODEL_DICT, key, default)
            end

            def set_mvar(key, value)
                model.set_attribute(MODEL_DICT, key, value)
            end

            def model_context
                @model_context ||= ModelContext.new(@instance.model)
            end

            def model_lenx;      model_context.lenx;      end
            def model_lenx=(v);  model_context.lenx = v;  end
            def model_leny;      model_context.leny;      end
            def model_leny=(v);  model_context.leny = v;  end
            def model_lenz;      model_context.lenz;      end
            def model_lenz=(v);  model_context.lenz = v;  end

            # --- Родитель ---
            def patro
                find_parent_chain.first
            end

            def parent_context
                p = patro
                p ? KCodeContext.new(p) : model_context
            end

            def instance
                @instance
            end

            # --- Вспомогательные методы (вызывают Axis и Side) ---
            def bounds_dim(axis)
                case axis
                when :x then @definition.bounds.width
                when :y then @definition.bounds.height
                when :z then @definition.bounds.depth
                end
            end

            def bounds_min(axis)
                case axis
                when :x then @definition.bounds.min.x
                when :y then @definition.bounds.min.y
                when :z then @definition.bounds.min.z
                end
            end

            def bounds_max(axis)
                case axis
                when :x then @definition.bounds.max.x
                when :y then @definition.bounds.max.y
                when :z then @definition.bounds.max.z
                end
            end

            def local_scale(axis)
                tr = @instance.transformation
                case axis
                when :x then tr.xscale
                when :y then tr.yscale
                when :z then tr.zscale
                end
            end

            def parent_scale_product(axis)
                find_parent_chain.inject(1.0) do |acc, anc|
                    tr = anc.transformation
                    s = case axis
                        when :x then tr.xscale
                        when :y then tr.yscale
                        when :z then tr.zscale
                        end
                    acc * s
                end
            end

            def parent_width_local(axis)
                p = patro
                if p
                    bb = clean_bounds(p.definition)
                    if bb.empty?
                        case axis
                        when :x then p.definition.bounds.width
                        when :y then p.definition.bounds.height
                        when :z then p.definition.bounds.depth
                        end
                    else
                        case axis
                        when :x then bb.width
                        when :y then bb.height
                        when :z then bb.depth
                        end
                    end
                else
                    case axis
                    when :x then model_context.lenx
                    when :y then model_context.leny
                    when :z then model_context.lenz
                    end
                end
            end

            def clean_bounds(definition)
                bb = Geom::BoundingBox.new
                definition.entities.each do |e|
                    next if e.is_a?(Sketchup::ComponentInstance)
                    next if e.is_a?(Sketchup::Group)
                    next unless e.respond_to?(:bounds)
                    bb.add(e.bounds)
                end
                bb
            end

            def position(axis)
                origin = @instance.transformation.origin
                case axis
                when :x then origin.x
                when :y then origin.y
                when :z then origin.z
                end
            end

            def apply_scale(axis, factor)
                KCode.suppress(@instance) do
                    scaling = case axis
                              when :x then Geom::Transformation.scaling(factor, 1, 1)
                              when :y then Geom::Transformation.scaling(1, factor, 1)
                              when :z then Geom::Transformation.scaling(1, 1, factor)
                              end
                    @instance.transformation = @instance.transformation * scaling
                end
            end

            def set_position(axis, value)
                KCode.suppress(@instance) do
                    tr      = @instance.transformation
                    current = position(axis)
                    delta   = value.to_f - current
                    translation = case axis
                                  when :x then Geom::Transformation.translation([delta, 0, 0])
                                  when :y then Geom::Transformation.translation([0, delta, 0])
                                  when :z then Geom::Transformation.translation([0, 0, delta])
                                  end
                    @instance.transformation = translation * tr
                end
            end

            def side_gap(side)
                axis, edge = Side::SIDES.fetch(side)
                p_scale    = parent_scale_product(axis)
                p_width    = parent_width_local(axis)
                pos        = position(axis)
                scale      = local_scale(axis)

                case edge
                when :min
                    (pos + bounds_min(axis) * scale) * p_scale
                when :max
                    return nil if p_width.nil?
                    (p_width - (pos + bounds_max(axis) * scale)) * p_scale
                end
            end

            def set_side_gap(side, value)
                axis, edge = Side::SIDES.fetch(side)
                p_scale    = parent_scale_product(axis)
                p_width    = parent_width_local(axis)
                scale      = local_scale(axis)
                local_gap  = value.to_f / p_scale

                case edge
                when :min
                    new_pos = local_gap - bounds_min(axis) * scale
                    set_position(axis, new_pos)
                when :max
                    return if p_width.nil?
                    new_pos = p_width - local_gap - bounds_max(axis) * scale
                    set_position(axis, new_pos)
                end
            end

            private

            def find_parent_chain
                result = []
                current = @instance
                loop do
                    parent = find_immediate_parent(current)
                    break if parent.nil?
                    result << parent
                    current = parent
                end
                result
            end

            def find_immediate_parent(inst)
                path = @instance.model.active_path
                if path && !path.empty? && path.length >= 2 && path.to_a.last == inst
                    return path.to_a[-2]
                end
                found = []
                walk_for_parent(@instance.model.entities, inst, found)
                found.first
            end

            def walk_for_parent(entities, target, result)
                entities.each do |e|
                    next unless e.is_a?(Sketchup::ComponentInstance)
                    inside = false
                    e.definition.entities.each do |child|
                        if child == target
                            inside = true
                            break
                        end
                    end
                    result << e if inside
                    walk_for_parent(e.definition.entities, target, result)
                end
            end
        end
    end
end