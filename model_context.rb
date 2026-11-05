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

            def global_scale_mask
                @model.get_attribute(MODEL_DICT, 'global_scale_mask', 0).to_i
            end

            def set_global_scale_mask_bits(bits, on)
                current = global_scale_mask
                new_mask = on ? (current | bits) : (current & ~bits)
                @model.set_attribute(MODEL_DICT, 'global_scale_mask', new_mask)
                new_mask
            end





            def patro;          nil; end
            def parent_context; nil; end

            # --- Код модели ---
            def code
                @model.get_attribute(MODEL_DICT, 'model_script', '')
            end

            def save_code(code_string)
                @model.set_attribute(MODEL_DICT, 'model_script', code_string)
            end

            def execute
                code_to_run = code
                return if code_to_run.nil? || code_to_run.empty?

                @model.start_operation('KCode Model Execute', true)
                begin
                    instance_eval(code_to_run)
                rescue => e
                    puts "[KCode/model] #{e.class}: #{e.message}"
                    puts e.backtrace.first(5).join("\n")
                ensure
                    @model.commit_operation
                end
            end
        end
    end
end