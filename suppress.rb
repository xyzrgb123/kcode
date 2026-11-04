# механизм подавления наблюдателей

module MyName
    module KCode
        @suppress_counts = Hash.new(0)

        def self.suppress(inst)
            return yield if inst.nil?
            return yield unless inst.respond_to?(:valid?) && inst.valid?
            id = inst.entityID
            @suppress_counts[id] += 1
            begin
                yield
            ensure
                @suppress_counts[id] -= 1
                @suppress_counts.delete(id) if @suppress_counts[id] <= 0
            end
        end

        def self.suppressed?(inst)
            return false if inst.nil?
            @suppress_counts[inst.entityID] > 0
        end
    end
end