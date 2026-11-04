module MyName
    module KCode
        def self.ctx_from_selection
            inst = Sketchup.active_model.selection.first
            unless inst.is_a?(Sketchup::ComponentInstance)
                raise '[KCode] Сначала выделите компонент в модели.'
            end
            KCodeContext.new(inst)
        end

        class PlacementObserver < Sketchup::ModelObserver
            def onPlaceComponent(arg)
                inst = case arg
                       when Sketchup::ComponentInstance then arg
                       when Sketchup::Model            then arg.entities.last
                       when Sketchup::Entities         then arg.last
                       else nil
                       end
                return unless inst.is_a?(Sketchup::ComponentInstance)
                return unless inst.valid?

                ctx = KCodeContext.new(inst)
                return if ctx.code.nil? || ctx.code.empty?

                begin
                    ctx.execute
                rescue => e
                    puts "[KCode/onPlace] #{e.class}: #{e.message}"
                end
            end
        end

        class InstanceObserver < Sketchup::EntityObserver
            def initialize
                @busy = {}
            end

            def onChangeEntity(entity)
                return unless entity.is_a?(Sketchup::ComponentInstance)
                return unless entity.valid?
                return if @busy[entity.entityID]

                @busy[entity.entityID] = true
                begin
                    execute_if_any(entity)
                    entity.definition.entities
                          .grep(Sketchup::ComponentInstance)
                          .each { |child| execute_if_any(child) if child.valid? }
                ensure
                    @busy.delete(entity.entityID)
                end
            end

            private

            def execute_if_any(inst)
                return unless inst.valid?
                return if @busy[inst.entityID]
                return if KCode.suppressed?(inst)
                return unless KCodeContext.new(inst).frozen?

                ctx = KCodeContext.new(inst)
                
                return if ctx.code.nil? || ctx.code.empty?

                @busy[inst.entityID] = true
                begin
                    ctx.execute
                rescue => e
                    puts "[KCode/onChange] #{inst.definition.name} #{e.class}: #{e.message}"
                ensure
                    @busy.delete(inst.entityID)
                end
            end
        end

        class TransactionObserver < Sketchup::ModelObserver
            def initialize
                @running = false
            end

            def onTransactionCommit(model)
                return if @running

                @running = true
                begin
                    model.entities.grep(Sketchup::ComponentInstance).each do |inst|
                        next unless inst.valid?
                        next if KCode.suppressed?(inst)
                        next unless KCodeContext.new(inst).frozen?
                        ctx = KCodeContext.new(inst)
                        next if ctx.code.nil? || ctx.code.empty?
                        begin
                            ctx.execute
                        rescue => e
                            puts "[KCode/onTxCommit] #{inst.definition.name} #{e.class}: #{e.message}"
                        end
                    end
                ensure
                    @running = false
                end
            end
        end

        class EntitiesAddedObserver < Sketchup::EntitiesObserver
            def onElementAdded(entities, entity)
                return unless entity.is_a?(Sketchup::ComponentInstance)
                return unless entity.valid?
                entity.add_observer($kcode_instance_observer) if $kcode_instance_observer
            end
        end


        class SelectionObserver < Sketchup::SelectionObserver
            def onSelectionBulkChange(_selection)
                KCode.handle_selection_changed
            end

            def onSelectionAdded(_selection, _entity)
                KCode.handle_selection_changed
            end

            def onSelectionRemoved(_selection, _entity)
                KCode.handle_selection_changed
            end

            def onSelectionCleared(_selection)
                KCode.handle_selection_changed
            end
        end



    end
end