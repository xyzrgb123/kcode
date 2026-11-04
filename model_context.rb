# «логический родитель» для top-level

module MyName
    module KCode
        # "Логический родитель" для top-level компонентов.
        # Предоставляет тот же интерфейс, что KCodeContext,
        # но берёт габариты из атрибутов модели.
        class ModelContext
            def initialize(model)
                @model = model
            end

            def model
                @model
            end

            def lenx; @model.get_attribute(MODEL_DICT, 'lenx'); end
            def lenx=(v); @model.set_attribute(MODEL_DICT, 'lenx', v.to_f); end
            def leny; @model.get_attribute(MODEL_DICT, 'leny'); end
            def leny=(v); @model.set_attribute(MODEL_DICT, 'leny', v.to_f); end
            def lenz; @model.get_attribute(MODEL_DICT, 'lenz'); end
            def lenz=(v); @model.set_attribute(MODEL_DICT, 'lenz', v.to_f); end

            def mvar(key, default = nil)
                @model.get_attribute(MODEL_DICT, key, default)
            end

            def set_mvar(key, value)
                @model.set_attribute(MODEL_DICT, key, value)
            end

            def patro;          nil; end
            def parent_context; nil; end
        end
    end
end